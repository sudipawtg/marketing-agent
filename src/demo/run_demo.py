"""Demo script for showcasing Marketing Agent capabilities"""

import asyncio
import sys
from pathlib import Path
from typing import Optional

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from src.agent import MarketingAgent
from src.data_collectors import CampaignContext
from src.utils import setup_logging
from src.demo.scenarios import DemoScenarios
import structlog
from datetime import datetime
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.markdown import Markdown

console = Console()
logger = structlog.get_logger()


class MarketingAgentDemo:
    """Interactive demo of the Marketing Agent"""
    
    def __init__(self):
        self.agent = MarketingAgent()
        self.scenarios = DemoScenarios()
    
    async def run_scenario(self, scenario_name: str, show_details: bool = True):
        """Run a specific demo scenario"""
        
        # Get scenario data
        scenario = self.scenarios.get_scenario(scenario_name)
        
        # Display scenario info
        scenario_info = self._get_scenario_info(scenario_name)
        console.print(Panel(
            f"[bold cyan]{scenario_info['title']}[/bold cyan]\n\n"
            f"{scenario_info['summary']}\n\n"
            f"[dim]Expected Recommendation: {scenario['expected_recommendation']}[/dim]",
            title="📊 Demo Scenario",
            border_style="cyan"
        ))
        
        # Inject scenario data into collectors
        self._inject_scenario_data(scenario_name, scenario)
        
        # Run analysis with progress indicator
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console
        ) as progress:
            task = progress.add_task("🤖 Agent analyzing campaign...", total=None)
            
            result = await self.agent.analyze_campaign(f"demo_{scenario_name}")
            
            progress.update(task, completed=True)
        
        console.print()
        
        if result.get("errors"):
            console.print(f"[bold red]❌ Errors occurred:[/bold red]")
            for error in result["errors"]:
                console.print(f"  • {error}")
            return
        
        # Display results
        self._display_results(result, show_details)
        
        return result
    
    def _inject_scenario_data(self, scenario_name: str, scenario: dict):
        """Inject scenario data into the agent's collectors"""
        # Override the collectors to return our scenario data
        campaign_id = f"demo_{scenario_name}"
        
        # Store scenario data for retrieval
        self.agent.context_builder.campaign_collector._cache[
            f"CampaignMetricsCollector:{campaign_id}:days=7"
        ] = (scenario["campaign_metrics"], datetime.now())
        
        self.agent.context_builder.creative_collector._cache[
            f"CreativeMetricsCollector:{campaign_id}:"
        ] = (scenario["creative_metrics"], datetime.now())
        
        self.agent.context_builder.competitor_collector._cache[
            f"CompetitorSignalsCollector:{campaign_id}:"
        ] = (scenario["competitor_signals"], datetime.now())
    
    def _get_scenario_info(self, scenario_name: str) -> dict:
        """Get scenario metadata"""
        scenarios = DemoScenarios.list_scenarios()
        for s in scenarios:
            if s["name"] == scenario_name:
                return s
        return {"title": "Unknown", "summary": ""}
    
    def _display_results(self, result: dict, show_details: bool = True):
        """Display analysis results in a beautiful format"""
        
        # Campaign Context Summary
        if result.get("context") and show_details:
            context = result["context"]
            cm = context.campaign_metrics
            
            context_table = Table(title="📈 Campaign Performance", show_header=True, border_style="blue")
            context_table.add_column("Metric", style="cyan", width=20)
            context_table.add_column("Current", style="white", width=15)
            context_table.add_column("Change", style="yellow", width=15)
            
            context_table.add_row(
                "CPA (Cost per Acquisition)",
                f"${cm.cpa:.2f}",
                f"[{'red' if cm.cpa_change_pct > 0 else 'green'}]{cm.cpa_change_pct:+.1f}%[/]"
            )
            context_table.add_row(
                "CTR (Click-Through Rate)",
                f"{cm.ctr:.2f}%",
                f"[{'green' if cm.ctr_change_pct > 0 else 'red'}]{cm.ctr_change_pct:+.1f}%[/]"
            )
            context_table.add_row(
                "CVR (Conversion Rate)",
                f"{cm.cvr:.2f}%",
                f"[{'green' if cm.cvr_change_pct > 0 else 'red'}]{cm.cvr_change_pct:+.1f}%[/]"
            )
            context_table.add_row(
                "Spend",
                f"${cm.spend:,.2f}",
                f"[{'yellow' if cm.spend_change_pct > 10 else 'white'}]{cm.spend_change_pct:+.1f}%[/]"
            )
            
            console.print(context_table)
            console.print()
            
            # Key signals
            cr = context.creative_metrics
            comp = context.competitor_signals
            
            signals_table = Table(title="🔍 Key Signals Detected", show_header=True, border_style="yellow")
            signals_table.add_column("Signal Type", style="cyan", width=25)
            signals_table.add_column("Status", style="white", width=50)
            
            signals_table.add_row(
                "Creative Status",
                f"{'[red]⚠ Fatigue Detected[/red]' if cr.fatigue_detected else '[green]✓ Healthy[/green]'} - "
                f"Age: {cr.avg_creative_age_days} days, Frequency: {cr.frequency:.1f}, Trend: {cr.ctr_trend.value}"
            )
            signals_table.add_row(
                "Competitive Pressure",
                f"[{'red' if comp.competitive_pressure == 'high' else 'yellow' if comp.competitive_pressure == 'medium' else 'green'}]"
                f"{comp.competitive_pressure.upper()}[/] - "
                f"Competition Score: {comp.auction_competition_score:.0f}/100, New Entrants: {comp.new_entrants_last_week}"
            )
            signals_table.add_row(
                "Market Activity",
                f"{'[red]↑' if comp.market_activity_change_pct > 20 else '[yellow]→' if comp.market_activity_change_pct > 10 else '[green]→'} "
                f"{comp.market_activity_change_pct:+.1f}%[/] change in competitor activity"
            )
            
            console.print(signals_table)
            console.print()
        
        # Signal Analysis
        if result.get("signal_analysis") and show_details:
            analysis = result["signal_analysis"]
            
            console.print(Panel(
                f"[bold]Root Cause:[/bold] {analysis.root_cause}\n\n"
                f"[bold]Key Evidence:[/bold]\n{analysis.supporting_evidence}\n\n"
                f"[bold]Confidence:[/bold] [{'green' if analysis.confidence >= 0.7 else 'yellow'}]{analysis.confidence:.0%}[/]",
                title="🧠 Agent's Analysis",
                border_style="magenta"
            ))
            console.print()
        
        # Recommendation
        if result.get("recommendation"):
            rec = result["recommendation"]
            
            # Color code risk level
            risk_colors = {"low": "green", "medium": "yellow", "high": "red"}
            risk_color = risk_colors.get(rec.risk_level.value, "white")
            
            # Confidence bar
            confidence_blocks = int(rec.confidence * 10)
            confidence_bar = "█" * confidence_blocks + "░" * (10 - confidence_blocks)
            confidence_color = "green" if rec.confidence >= 0.7 else "yellow" if rec.confidence >= 0.5 else "red"
            
            console.print(Panel(
                f"[bold yellow]⚡ {rec.recommended_workflow.value}[/bold yellow]\n\n"
                f"[bold]Confidence:[/bold] [{confidence_color}]{confidence_bar}[/] {rec.confidence:.0%}\n"
                f"[bold]Risk Level:[/bold] [{risk_color}]{rec.risk_level.value.upper()}[/{risk_color}]\n\n"
                f"[bold]Why this action?[/bold]\n{rec.reasoning}\n\n"
                f"[bold]Expected Impact:[/bold]\n{rec.expected_impact}\n\n"
                f"[bold]Timeline:[/bold] {rec.timeline}\n"
                f"[bold]Success Criteria:[/bold] {rec.success_criteria}",
                title="💡 Agent's Recommendation",
                border_style="green"
            ))
            
            # Show alternatives if present
            if rec.alternatives and show_details:
                console.print("\n[dim]Alternative actions considered:[/dim]")
                for alt in rec.alternatives:
                    console.print(f"  • {alt.workflow.value}: {alt.why_not_recommended}")
        
        console.print()
    
    async def run_interactive_demo(self):
        """Run an interactive demo allowing scenario selection"""
        
        console.print(Panel(
            "[bold cyan]Marketing Agent - Interactive Demo[/bold cyan]\n\n"
            "This demo showcases the agent's reasoning capabilities across different scenarios.\n"
            "The agent analyzes campaign data, correlates signals, and recommends specific actions.",
            title="🤖 Welcome",
            border_style="cyan"
        ))
        console.print()
        
        while True:
            # Show scenario menu
            scenarios = DemoScenarios.list_scenarios()
            
            console.print("[bold]Available Demo Scenarios:[/bold]\n")
            for i, scenario in enumerate(scenarios, 1):
                console.print(f"{i}. {scenario['title']}")
                console.print(f"   [dim]{scenario['summary']}[/dim]\n")
            
            console.print("A. Run ALL scenarios")
            console.print("Q. Quit\n")
            
            choice = console.input("[bold cyan]Select a scenario (1-5, A, Q):[/bold cyan] ").strip().upper()
            
            if choice == 'Q':
                console.print("\n[bold green]Thanks for exploring the Marketing Agent demo! 👋[/bold green]")
                break
            elif choice == 'A':
                console.print("\n[bold]Running all scenarios...[/bold]\n")
                for scenario in scenarios:
                    await self.run_scenario(scenario['name'], show_details=False)
                    console.print("\n" + "="*80 + "\n")
            elif choice.isdigit() and 1 <= int(choice) <= len(scenarios):
                scenario = scenarios[int(choice) - 1]
                console.print()
                await self.run_scenario(scenario['name'], show_details=True)
                console.print("\n" + "="*80 + "\n")
            else:
                console.print("[red]Invalid choice. Please try again.[/red]\n")


async def main():
    """Main entry point"""
    setup_logging("INFO")
    
    demo = MarketingAgentDemo()
    
    # Check command line args
    if len(sys.argv) > 1:
        scenario_name = sys.argv[1]
        if scenario_name == "--list":
            console.print("[bold]Available scenarios:[/bold]")
            for s in DemoScenarios.list_scenarios():
                console.print(f"  • {s['name']}: {s['summary']}")
        elif scenario_name == "--all":
            console.print("[bold cyan]Running all demo scenarios...[/bold cyan]\n")
            for scenario in DemoScenarios.list_scenarios():
                await demo.run_scenario(scenario['name'], show_details=True)
                console.print("\n" + "="*80 + "\n")
        else:
            await demo.run_scenario(scenario_name, show_details=True)
    else:
        # Interactive mode
        await demo.run_interactive_demo()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        console.print("\n\n[yellow]Demo interrupted by user[/yellow]")
    except Exception as e:
        console.print(f"\n[bold red]Error:[/bold red] {str(e)}")
        raise
