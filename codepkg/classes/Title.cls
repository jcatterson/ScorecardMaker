public class Title
{
	public Id id { get; private set;}
	public Table table { get; set; }

	public List<Title> subtitles {get; private set;}
	public String label {get; set;}
	public String css { get; set;}
	public Map<String, Column> columns {get; set;}
	public Scorecard card { get; set; }
	public String uniqueName { get; private set; }

	public Title(String label)
	{
		subtitles = new List<Title>();
		columns = new Map<String, Column>();
		this.label = label;
	}

	public Title(Title__c t)
	{
		this( t.Name );
		id = t.Id;
	}

	public Title(String label, String uniqueName)
	{
		this(label);
		this.uniqueName = uniqueName;
	}

	public static Map<Id, Title> createTitles( Map<Id, Title__c> allTitles  )
	{
		Map<Id, Title> memoryTitles = new Map<Id, Title>();
		for( Title__c someTitle : allTitles.values() )
		{
			memoryTitles.put( someTitle.Id, new Title( someTitle ) );
		}
		for( Title someTitle : memoryTitles.values() )
		{
			// assume a validation rule exists, not allowing a parentitle to belong to a different scorecard
			Id parentId = allTitles.get( someTitle.Id ).Parent_Title__c;
			if( parentId != null && memoryTitles.containsKey( parentId ) )
			{
				Title parentTitle = memoryTitles.get( parentId );
				parentTitle.addSubTitle( someTitle );
			}
		}
		return memoryTitles;
	}

	public static List<Title> buildDynamicTitles( String sObjectName, String pickListAPIField )
	{
		List<Title> titles = new List<Title>();
		List<Schema.PicklistEntry> picklistValues;
		try
		{
			picklistValues = Schema.getGlobalDescribe().get( sObjectName ).getDescribe().fields.getMap().get( pickListAPIField ).getDescribe().getPicklistValues();
		}
		catch(Exception e)
		{
			return null;
			throw new UnknownFieldOrObjectException('The sObject or the field may have not existed.  It is also possible that the field and sObject existed, but the field was not a picklist' +
                                                    'sObject: ' + sObjectName + ' Field: ' + pickListAPIField);
		}
		for( Schema.PicklistEntry picklist : picklistValues )
		{
			Title t = new Title( picklist.getValue() );
			titles.add( t );
		}
		return titles;
	}

	public class UnknownFieldOrObjectException extends Exception {}

	public void addSubTitle(Title subtitle)
	{
		subtitles.add(subtitle);
	}

	public Title addSubTitle(String titleName)
	{
		Title newTitle = new Title(titleName);
		subtitles.add( newTitle );
		return newTitle;
	}

	public Title addSubTitle(String titleName, String uniqueName)
	{
		Title newTitle = new Title(titleName, uniqueName);
		subtitles.add( newTitle );
		return newTitle;
	}

	public boolean isLeaf
	{
		get
		{
			return subtitles.isEmpty();
		}
	}
	public integer getColspan()
	{
		if( isLeaf )
		{
			return 1;
		}
		List<List<Title>> children = getAllChildrenAndGrandchildren();
		List<Title> lastLayer = children[children.size()-1];
		return lastLayer.size();
	}

	private void buildGrandchildrenStructure(List<List<Title>> titles, integer layer)
	{
		if(titles.size() <= layer)
		{
			titles.add( new List<Title>() );
		}
		titles[layer++].add(this);
		if( isLeaf )
		{
			return;
		}
		else
		{
			for(Title child : subtitles)
			{
				child.buildGrandchildrenStructure(titles, layer);
			}
		}
	}

	public List<List<Title>> getAllChildrenAndGrandchildren()
	{
		List<List<Title>> titles = new List<List<Title>>();
		buildGrandchildrenStructure( titles, 0 );
		return titles;
	}

    public static List<Title> parseTitles(String jsonString)
    {
		List<Title> titles = new List<Title>();
        JSONParser parser = JSON.createParser( jsonString );
        while( parser.nextToken() != null )
        {
            while( parser.getCurrentToken() == JSONToken.START_OBJECT )
            {
                Title item = (Title)parser.readValueAs( Title.class );
                titles.add( item );
            }
        }
        return titles;
    }

}