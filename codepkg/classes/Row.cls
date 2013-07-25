global virtual class Row implements Comparable
{
	public String name { get; private set; }
	public String aliasName { get; set; }
	public Map<String, Cell> columnMap { get; private set; }
	public String rowType {get; private set;}

	public Row( String name, String rowType )
	{
		this.name = name;
		this.columnMap = new Map<String, Cell>();
		this.rowType = rowType;
	}

	public void addColumn(Cell cellToAdd)
	{
		columnMap.put( cellToAdd.columnName, cellToAdd );
	}

	public void addColumns(Map<String, Cell> newColumns)
	{
		columnMap = combineMaps( newColumns, columnMap );
	}

	public virtual void checkCellBelowTarget(String targetColumnName, String actualColumnName)
	{
		Cell targetCell = columnMap.get(targetColumnName);
		Cell actualCell = columnMap.get(actualColumnName);
		if(actualCell != null && targetCell != null && targetCell.value > actualCell.value)
		{
			actualCell.isBelowTarget = true;
		}
	}

	global integer compareTo( Object other )
	{
		if( other instanceof Row )
		{
			Row otherRow = (Row)other;
			if( name == otherRow.name )
				return 0;
			if( name > otherRow.name )
				return 1;
		}
		return -1;
	}

	public class Region extends Row
	{
		public List<Division> divisions { get; private set; }

		public Region( String name )
		{
			super( name, '' );
			divisions = new List<Division>();
		}

		public void addDivision( Division newDivision )
		{
			divisions.add( newDivision );
		}

		public override void  checkCellBelowTarget(String goalCellName, String actualCellName)
		{
			super.checkCellBelowTarget(goalCellName, actualCellName);
			for(Division div : divisions)
			{
				div.checkCellBelowTarget(goalCellName, actualCellName);
			}
		}

	}

	public class Division extends Row
	{
		public Division( String name )
		{
			super( name, '' );
		}
	}

	public class GrandTotal extends Row
	{
		public GrandTotal()
		{
			super( 'Grand Total', '' );
		}
	}

	public static Map<String, Cell> combineMaps( Map<String, Cell> primary, Map<String, Cell> secondary )
	{
		Map<String, Cell> combined = secondary.clone();

		combined.putAll( primary );

		return combined;
	}
}