public abstract class Column
{
	public static Column createColumn( Field__c field )
	{
		if( field.RecordType.DeveloperName == 'Sum')
			return new Column.SumColumn( field.Row__r.Alias__c, '', 'css', Column.CURRENCY_TYPE, field.API_Name__c );
		else if( field.RecordType.DeveloperName == 'Count' )
			return new Column.CountColumn( field.Row__r.Alias__c, '', 'css' ); // maybe we want to count something different than id?		
		throw new UnknownRecordTypeException('Im sorry, but the Developer Name for Id: ' + field.Id +
                                             ' Does not exist. Perhaps someone renamed the API name the specified record type?');
	}
	public class UnknownRecordTypeException extends Exception {}	

	public static final String NUMBER_TYPE = 'number';
	public static final String CURRENCY_TYPE = 'currency';
	public static final String PERCENT_TYPE = 'percent';
	public String name { get; private set; }
	public String label { get; private set; }
	public String type { get; private set; }
	public String headerClass { get; private set; }
	public String css {get; private set;}
		
	public Boolean getIsPercent()
	{
		return type == PERCENT_TYPE;
	}

	public Boolean getIsNumber()
	{
		return type == NUMBER_TYPE;
	}

	public Boolean getIsCurrency()
	{
		return type == CURRENCY_TYPE;
	}

	public Column( String name, String label, String headerClass, String type )
	{
		this.name = name;
		this.label = label;
		this.type = type;
		this.headerClass = headerClass;
	}

	public String field;
	public String recordType;
	public String alias;
	public virtual String getFieldExpression()
	{
		if( field == null) return '';
		return recordType + '(' + field + ') ' + name;
	}


	public virtual Decimal getValue( AggregateResult result )
	{
		return (Decimal)result.get( name );
	}
	
	public class ColumnHeader extends Column
	{
		public ColumnHeader(String name, String label, String headerClass, String type)
		{
			super(name, label, headerClass, type);
		}
		
		/*
		* Method should not be called
		* @throws UnusedMethodCalledException
		*/
		public override String getFieldExpression()
		{
			throw new IllegalMethodCallException('This method is only implemented to meet the definition of the abstract class, it should not be called');
		}
	}

	public virtual class SumColumn extends Column
	{
		public String field { get; private set; }

		public SumColumn( String name, String label, String headerClass, String type, String field )
		{
			super( name, label, headerClass, type );
			this.field = field;
		}

		public override String getFieldExpression()
		{
			return 'SUM(' + field + ') ' + name;
		}
	}
	
	public virtual class AverageColumn extends Column
	{
		public String field { get; private set; }

		public AverageColumn( String name, String label, String headerClass, String type, String field )
		{
			super( name, label, headerClass, type );
			this.field = field;
		}

		public override String getFieldExpression()
		{
			return 'AVG(' + field + ') ' + name;
		}
	}
	
	public class SumColumnRounded extends SumColumn
	{
		public SumColumnRounded( String name, String label, String headerClass, String type, String field )
		{
			super( name, label, headerClass, type, field );
		}
		
		public override Decimal getValue( AggregateResult result )
		{ 
			return (Decimal)Math.round( (Decimal)result.get( name ) );
		}
	}

	public class CountColumn extends Column
	{
		public CountColumn( String name, String label, String headerClass )
		{
			super( name, label, headerClass, NUMBER_TYPE );
		}

		public override String getFieldExpression()
		{
			return 'COUNT(Id) ' + name;
		}
	}

	// NOTE: Do NOT try to add to a QueryGroup.
	public class EmptyColumn extends Column
	{
		public EmptyColumn( String name )
		{
			super( name, '', '', '' );
		}

		public override String getFieldExpression()
		{
			throw new IllegalMethodCallException( 'Cannot add EmptyColumn to QueryGroup' );
		}
	}

	public static final EmptyColumn empty = new EmptyColumn( 'emptyCOLUMN' );

	public class IllegalMethodCallException extends Exception {}
}