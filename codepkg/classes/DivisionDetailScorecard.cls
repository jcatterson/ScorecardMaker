public class DivisionDetailScorecard
{
/*	public class SimplifiedToolbar
	{
		public String startDate, endDate, quarter, month, year;
		public SimplifiedToolbar(DivisionDetailScorecard toolbar)
		{
			this.startDate = toolbar.startDate;
			this.endDate = toolbar.endDate;
			this.quarter = toolbar.quarter;
			this.month = toolbar.month;
			this.year = toolbar.year;
		}		
	}

	public Boolean displayStartDate {get; set;}
	public String startDate {get; set;}
	public void setStartDate( String startDate )
	{
		this.startDate = startDate;
		changeEvents.add(ScorecardEvent.START_DATE);
	}

	public Boolean displayEndDate {get; set;}
	public String endDate {get;set;}
	public void setEndDate(String endDate)
	{
		this.endDate = endDate;
		changeEvents.add(ScorecardEvent.END_DATE);
	}

	public Boolean displayMonth {get; set;}
	public String month {get;set;}
	public void setMonth(String month)
	{
		this.month = month;
		changeEvents.add(ScorecardEvent.MONTH);
	}

	public Boolean displayQuarter {get; set;}
	public String quarter{get; set;}
	public void setQuarter(String quarter)
	{
		this.quarter = quarter;
		changeEvents.add( ScorecardEvent.QUARTER );
	}

	public Boolean displayYear {get; set;}
	public String year {get; set;}
	public void setYear(String year)
	{
		this.year = year;
		changeEvents.add( ScorecardEvent.YEAR );
	}

	public Boolean displayDivision { get; set; }
	public String currentDivision { get; set; }
	public void setCurrentDivision(String division)
	{
		this.currentDivision = division;
		changeEvents.add( ScorecardEvent.DIVISION );
	}

	public Boolean displayRegion { get; set; }
	public String currentRegion { get; set;}
	public void setCurrentRegion(String region)
	{
		this.currentRegion = region;
		changeEvents.add( ScorecardEvent.REGION );
	}

	public String headersName { get; set; }

	private Set<ScorecardEvent> changeEvents;

	public static String GRAND_TOTAL { get { return 'All Regions'; } }

	public String pageRenderType { get; private set; }
	public String pageContentType { get; private set; }
	public static final String PDF_RENDER_TYPE = 'PDF';
	public static final String EXCEL_CONTENT_TYPE = 'application/vnd.ms-excel';

	private List<ScorecardListener> subscribers {private get; private set;}
	public DivisionDetailScorecard ourInstance { get; private set;}
	public DivisionDetailScorecard()
	{
		changeEvents = new Set<ScorecardEvent>();
		pageRenderType = '';
		pageContentType = '';
		displayRegion = true;
		displayDivision = true;
		displayStartDate = true;
		displayEndDate = true;
		displayMonth = true;
		displayQuarter = true;
		displayYear = true;
		startDate = Date.today().toStartOfMonth().format();
		endDate = Date.today().format();
		month = String.valueOf( Date.today().month() );
		year = String.valueOf( Date.today().year() );
		quarter = String.valueOf( ( (Decimal)Date.today().month() ).divide( 3, 0, System.RoundingMode.CEILING ) );

		currentDivision = selectableDivisions[0].getValue();
		currentRegion = GRAND_TOTAL;
		ourInstance = this;
		subscribers = new List<ScorecardListener>();
		changeEvents = new Set<ScorecardEvent>();
	}

	public void requery()
	{
		notify( changeEvents );	
		changeEvents = new Set<ScorecardEvent>();
	}

	public void notify( Set<ScorecardEvent> events )
	{
		for( ScorecardListener l : subscribers )
		{
			l.scorecardEvent( events );
		}	
	}

	public List<Account> regionDivisions
	{
		get
		{
			if(regionDivisions == null)
			{
				regionDivisions = [Select Name, Region__c
				                   from Account
				                where RecordType.DeveloperName = 'Division_Record_Type'
				                  AND Region__c != null
				                  AND Open__c = true
				                ];
			}
			return regionDivisions;
		}
		private set;
	}

	public List<SelectOption> selectableRegions
	{
		get
		{
			if(selectableRegions == null)
			{
				selectableRegions = new List<SelectOption>();
				Map<String, String> regionMap = new Map<String, String>();
				for(Account division : regionDivisions)
				{
					String regionName = division.Region__c;
					if( !regionMap.containsKey(regionName) )
					{
						selectableRegions.add( new SelectOption(regionName, regionName) );
						regionMap.put(regionName, regionName);
					}
				}
				selectableRegions.add( new SelectOption(GRAND_TOTAL, GRAND_TOTAL) );
				selectableRegions.sort();
			}
			return selectableRegions;
		}
		private set;
	}

	public List<SelectOption> selectableDivisions
	{
		get
		{
			if(selectableDivisions == null)
			{
				selectableDivisions = new List<SelectOption>();
				for(Account division : regionDivisions)
				{
					selectableDivisions.add( new SelectOption(division.name, division.name) );
				}
			}
			selectableDivisions.sort();
			return selectableDivisions;
		}
		private set;
	}

	public Boolean displayingHTML
	{
		get
		{
			return pageRenderType == '' && pageContentType == '';
		}
	}

	public void displayExcel()
	{
		pageRenderType = '';
		pageContentType = EXCEL_CONTENT_TYPE;
	}

	public void displayPDF()
	{
		pageContentType = '';
		pageRenderType = PDF_RENDER_TYPE;
	}

	public void subscribe( ScorecardListener sc )
	{
		subscribers.add( sc );		
	}

	public enum ScorecardEvent{START_DATE, END_DATE, QUARTER, YEAR, MONTH, DIVISION, REGION, DATE_CHANGE, PDF, EXCEL}

	public interface ScorecardListener
	{
		void scorecardEvent( Set<ScorecardEvent> events );
		void setToolbar( DivisionDetailScorecard toolbar );
	}

	public abstract class ScorecardListenerUpdate implements ScorecardListener
	{
		public DivisionDetailScorecard toolbar { get; private set;}
		public void setToolbar( DivisionDetailScorecard toolbar )
		{
			if( this.toolbar == null )
			{
				this.toolbar = toolbar;
				toolbar.subscribe( this );
				runCard();
			}
		}

		public abstract void runCard();

		public void scorecardEvent( Set<ScorecardEvent> events )
		{
			runCard();
		}
	}*/
}