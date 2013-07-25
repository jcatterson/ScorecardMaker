public class QueryGroup
{
	private Id queryGroupInstantiatedFrom;
	public static final String QUERY_PREFIX = 'SELECT ';
	public static final String QUERY_GROUP_BY = ' GROUP BY ROLLUP (';

	private String condition;
	public String objectType { get; private set;}
	public transient Scorecard.Rollup rollup { get; private set;}
	private transient Scorecard.GlobalCondition globalCondition;

	public List<Column> columns { get; private set; }

	public QueryGroup( String objectType, Scorecard.Rollup rollup, String condition )
	{
		this.objectType = objectType;
		this.condition = condition;
		this.columns = new List<Column>();
		this.rollup = rollup;
	}


/*	public static List<QueryGroup> buildQueryGroups( List<QueryGroup__c> queries )
	{
		List<QueryGroup> queryGroups = new List<QueryGroup>();
		for( QueryGroup__c q : queries )
		{
			queryGroups.addAll( buildQueryGroups( q ) );
		}
		return queryGroups;
	}

	public static List<QueryGroup> buildQueryGroups( QueryGroup__c query )
	{
		List<QueryGroup> queriesCreated = new List<QueryGroup>();
		Map<String, Set<Field__c>> caseToFields = findFieldsForUniqueCaseStatements( query );
		for(String caseCondition : caseToFields.keySet() )
		{
			Set<Field__c> fields = caseToFields.get( caseCondition );
			String condition = String.isBlank( query.Condition__c ) ? (String.isBlank(caseCondition) ? '' : caseCondition) : query.Condition__c + ( String.isBlank( caseCondition ) ? '' : ' and ' + caseCondition ); 
			QueryGroup newQuery = new QueryGroup( query.TableName__c, null, condition );
			for(Field__c field : fields )
			{
				newQuery.add( Column.createColumn( field ) );
			}
			queriesCreated.add( newQuery );
		}
		return queriesCreated;
	}

	private static Map<String, Set<Field__c>> findFieldsForUniqueCaseStatements( QueryGroup__c query )
	{
		Map<String, Set<Field__c>> caseToFields = new Map<String, Set<Field__c>>();
		for( Field__c field : query.Fields__r )
		{
			if( !caseToFields.containsKey( field.Condition__c ) )
				caseToFields.put( field.Condition__c, new Set<Field__c>() ); 
			caseToFields.get( field.Condition__c ).add( field );
		}
		return caseToFields;
	}
*/
	public QueryGroup( QueryGroup copyFrom )
	{
		this( copyFrom.objectType, copyFrom.rollup, copyFrom.condition );
		for( Column c : copyFrom.columns )
		{
			add( c );
		}
	}

	public String getQuery()
	{
		String query = QUERY_PREFIX;
		if( rollup != null )
			query += rollup.getRollupFields(objectType) + ',';
		if( columns == null || columns.size() == 0 || String.isBlank(objectType) ) return '';
		for( Column aColumn : columns )
		{
			query += aColumn.getFieldExpression() + ',';
		}
		query = query.removeEnd(',');
		query += ' FROM ' + objectType;
		if( !String.isEmpty(condition) )
		{
			query += ' WHERE ' + condition;
		}

		if( globalCondition != null )
		{
			String additionalWhere = globalCondition.getCondition(objectType);
			if( !String.isEmpty(additionalWhere) && !String.isEmpty(condition))
			{
				query += ' AND ' + additionalWhere + ' ';
			}
			else if( !String.isEmpty(additionalWhere) )
			{
				query += ' WHERE ' + additionalWhere + ' ';
			}
		}

		if( rollup != null )
		{
			query += QUERY_GROUP_BY;
			query += rollup.getGroupByStatement(objectType);
			query += ')';
		}

		return query;
	}

	public void setGlobalCondition(Scorecard.GlobalCondition globalCondition)
	{
		this.globalCondition = globalCondition;
	}

	public void add( Column newColumn )
	{
		columns.add( newColumn );
	}

	public Map<String, Cell> getInitialValues()
	{
		Map<String, Cell> valueMap = new Map<String, Cell>();
		if( columns == null ) return null;
		for( Column aColumn : columns )
		{
			valueMap.put( aColumn.name, new Cell(aColumn.name, null) );
		}

		return valueMap;
	}

	public Map<String, Cell> getValues( AggregateResult result )
	{
		Map<String, Cell> valueMap = new Map<String, Cell>();

		for( Column aColumn : columns )
		{
			System.assertNotEquals( null, aColumn.name, 'name dne');
			System.assertNotEquals( null, result, 'result dne' );
			valueMap.put( aColumn.name, new Cell(aColumn.name, aColumn.getValue( result )) );
		}

		return valueMap;
	}
}