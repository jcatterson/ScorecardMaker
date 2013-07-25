global class Cell
{
	public String columnName;
	public Decimal value { get; private set; }
	public Boolean isBelowTarget { get; set; }
	public String css { get; set; }
	public static final String ON_TARGET_CSS = 'onTarget';
	public static final String BELOW_TARGET_CSS = 'notOnTarget';
	public static final String HIT_TARGET_CSS = 'hitTarget';
	
	public Cell(String columnName, Decimal value)
	{
		this.columnName = columnName;
		this.value = value;
		isBelowTarget = false;
		css = '';
	}	



	public static Map<String, Cell> mapColumnNameToCell( Map<String, Object> myColumns )
	{
		Map<String, Cell> columnToCell = new Map<String, Cell>();
		for(String columnName : myColumns.keySet())
		{
			Map<String, Object> fieldToValue = (Map<String, Object>)myColumns.get(columnName);
			Boolean belowTarget = (Boolean)fieldToValue.get('isBelowTarget');
			Decimal value = (Decimal)fieldToValue.get('value');
			Cell myCell = new Cell(columnName, value);
			myCell.isBelowTarget = belowTarget;
			columnToCell.put(columnName, myCell );	
		}
		return columnToCell;
	}

	public static void compareCellsByPercentages( Cell actualCell, Cell goalCell )
	{
		if( goalCell != null && goalCell.value != null && actualCell != null && actualCell.value != null)
		{
			Decimal numerator = actualCell.value;
			Decimal denominator = goalCell.value;

			if( denominator != 0 )
			{
				Decimal quotient = numerator.divide( denominator, 2 );
				if( quotient < .9 )
				{
					actualCell.css = BELOW_TARGET_CSS;
				}
				else if( quotient > .9 && quotient <= .99)
				{
					actualCell.css = ON_TARGET_CSS;
				}
				else
				{
					actualCell.css = HIT_TARGET_CSS;
				}
			}
		}
		else if( (actualCell != null && actualCell.value == null) && ( goalCell != null && goalCell.value != null && goalCell.value != 0) )
			actualCell.css = BELOW_TARGET_CSS;
	}
}