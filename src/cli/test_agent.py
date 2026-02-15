"""CLI tool for testing the agent"""

import asyncio
import sys
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.agent import MarketingAgent
from src.utils import setup_logging
import structlog
import json

logger = structlog.get_logger()


async def main():
    """Run agent analysis from CLI"""
    setup_logging("INFO")
    
    if len(sys.argv) < 2:
        print("Usage: python -m src.cli.test_agent <campaign_id>")
        print("Example: python -m src.cli.test_agent campaign_12345")
        sys.exit(1)
    
    campaign_id = sys.argv[1]
    
    logger.info("Starting agent analysis", campaign_id=campaign_id)
    
    try:
        agent = MarketingAgent()
        result = await agent.analyze_campaign(campaign_id)
        
        print("\n" + "="*80)
        print("CAMPAIGN ANALYSIS RESULTS")
        print("="*80)
        
        if result.get("errors"):
            print("\n❌ ERRORS:")
            for error in result["errors"]:
                print(f"  - {error}")
            return
        
        # Print context
        if result.get("context"):
            print("\n📊 CAMPAIGN CONTEXT:")
            context = result["context"]
            cm = context.campaign_metrics
            print(f"  Campaign: {cm.campaign_name}")
            print(f"  CPA: ${cm.cpa:.2f} ({cm.cpa_change_pct:+.1f}%)")
            print(f"  CTR: {cm.ctr:.2f}% ({cm.ctr_change_pct:+.1f}%)")
            print(f"  Spend: ${cm.spend:,.2f}")
        
        # Print signal analysis
        if result.get("signal_analysis"):
            print("\n🔍 SIGNAL ANALYSIS:")
            analysis = result["signal_analysis"]
            print(f"  Root Cause: {analysis.root_cause}")
            print(f"  Confidence: {analysis.confidence:.0%}")
        
        # Print recommendation
        if result.get("recommendation"):
            rec = result["recommendation"]
            print(f"\n💡 RECOMMENDATION:")
            print(f"  Workflow: {rec.recommended_workflow.value}")
            print(f"  Risk Level: {rec.risk_level.value.upper()}")
            print(f"  Confidence: {rec.confidence:.0%}")
            print(f"\n  Reasoning:")
            print(f"  {rec.reasoning}")
            print(f"\n  Expected Impact:")
            print(f"  {rec.expected_impact}")
        
        # Print metadata
        if result.get("metadata"):
            print(f"\n⏱️  METADATA:")
            meta = result["metadata"]
            if "context_collection_ms" in meta:
                print(f"  Context Collection: {meta['context_collection_ms']}ms")
            if "total_iterations" in meta:
                print(f"  Iterations: {meta['total_iterations']}")
        
        print("\n" + "="*80)
        
        # Optionally save full result to JSON
        if "--save" in sys.argv:
            output_file = f"result_{campaign_id}.json"
            with open(output_file, "w") as f:
                # Convert result to JSON-serializable format
                json_result = {
                    "campaign_id": result["campaign_id"],
                    "recommendation": rec.model_dump() if rec else None,
                    "signal_analysis": analysis.model_dump() if analysis else None,
                    "metadata": result.get("metadata")
                }
                json.dump(json_result, f, indent=2, default=str)
            print(f"\n✅ Full result saved to {output_file}")
        
    except Exception as e:
        logger.error("Analysis failed", error=str(e))
        print(f"\n❌ Error: {str(e)}")
        raise


if __name__ == "__main__":
    asyncio.run(main())
