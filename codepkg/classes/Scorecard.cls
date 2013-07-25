global class Scorecard
{
	public static final String REGION_ALIAS = 'region';
	public static final String DIVISION_ALIAS = 'division';

	public transient List<QueryGroup> queryGroups;
	public JoinerTable tableForJoin { get; private set;}

	public String type { get; private set; }
	public List<Column> cols { get; private set; }
	public Title mainTitle {get; private set;}
	public List<List<Title>> titles { get{ if(titles == null) titles = mainTitle.getAllChildrenAndGrandchildren(); return titles;} private set; }

	public Integer lastTitleLayer { get { return titles.size()-1; } }
	public List<Row__c> myRows { get; private set; }
	public List<JoinerTable> titlesData { get; private set; }

/*	public Scorecard( Id scorecardId )
	{
		Scorecard__c sc = [Select Id, Title__r.RecordType.DeveloperName, Title__r.Id, RecordType.DeveloperName, Title__r.sObject_API_Name__c, Title__r.Picklist_API_Name__c,
                                  (Select Name, Alias__c from Rows__r),
                                  (Select Parent_Title__c, Name, QueryGroup__c, RecordType.DeveloperName from Titles__r)
                             from Scorecard__c
                           where Id = :scorecardId
                          ];
		myRows = sc.Rows__r;
		type = sc.RecordType.DeveloperName;
		Map<Id, Title__c> databaseTitles = new Map<Id, Title__c>( sc.Titles__r );
		Map<Id, Title> scorecardTitles;
		if( sc.Title__r.RecordType.DeveloperName == 'Standard' )
		{
			scorecardTitles = Title.createTitles( databaseTitles );
			titles = scorecardTitles.get( sc.Title__c ).getAllChildrenAndGrandchildren();
			System.assertNotEquals( null, titles, 'It is expected that a scorecard has a title. Scorecard Id:' + scorecardId );
			Set<Id> titlesQueryIds = Pluck.ids( 'QueryGroup__c', sc.Titles__r );

			Map<Id, QueryGroup__c> queries = new Map<Id, QueryGroup__c>(
										  [Select TableName__c, Condition__c,
												  (Select Name, Condition__c, Row__r.Alias__c, API_Name__c, RecordType.DeveloperName from Fields__r)
											 from QueryGroup__c
										   where Id = :titlesQueryIds]
										  );

			for(Title t : titles[lastTitleLayer])
			{
				List<QueryGroup> titlesQueries;
				if( queries.containsKey( databaseTitles.get( t.id ).QueryGroup__c ) )
				{
					titlesQueries = QueryGroup.buildQueryGroups( queries.get( databaseTitles.get( t.id ).QueryGroup__c ) );
					Table myTable = new Table( myRows, titlesQueries );
					t.table = myTable;
				}
			}
		}
		else if( sc.Title__r.RecordType.DeveloperName == 'Dynamic_Picklist' )
		{
			List<Title> pickListTitles= Title.buildDynamicTitles( sc.Title__r.sObject_API_Name__c, sc.Title__r.Picklist_API_Name__c );
			titles = new List<List<Title>>{ pickListTitles };
		}
		else
		{
			throw new UnhandledTitleRecordTypeException('The record type was not handled. Could have the developer name been changed? ' + sc.Title__r.RecordType.DeveloperName);
		}

	}*/
	public class UnhandledTitleRecordTypeException extends Exception {}

	public Scorecard( JoinerTable tableForJoin )
	{
		queryGroups = new List<QueryGroup>();
		this.tableForJoin = tableForJoin;
	}

	public Scorecard()
	{
		this( new JoinerTable() );
	}
	public void initialize(){}

	public static void compareScorecardByPercentages(Scorecard goalCard, Scorecard actualCard)
	{
		Set<String> allRows = new Set<String>( goalCard.tableForJoin.rowsByName.keyset() );
		allRows.addAll( actualCard.tableForJoin.rowsByName.keySet() );
		for( String rowName : allRows )
		{
			Row goalRow = goalCard.tableForJoin.rowsByName.get( rowName );
			Row actualRow = actualCard.tableForJoin.rowsByName.get( rowName );
			if( goalRow != null )
			{
				Set<String> allColumns = new Set<String>( goalRow.columnMap.keySet() );
				if( actualRow != null )
					allColumns.addAll( actualRow.columnMap.keySet()  );
				for( String colName : allColumns )
				{
					Cell actualCell;
					Cell goalCell;
					if( actualRow.columnMap.containsKey( colName ) )
						actualCell = actualRow.columnMap.get( colName );
					if( goalRow.columnMap.containsKey( colName ) )
						goalCell = goalRow.columnMap.get( colName );

					Cell.compareCellsByPercentages( actualCell, goalCell );
				}
			}
		}
	}

	public static Scorecard comparatorScorecard(Scorecard subtractFromCard, Scorecard subtractCard) // maybe this should be another type of Scorecard?
	{
		Scorecard comparator = new Scorecard();
		Set<String> allRows = new Set<String>( subtractFromCard.tableForJoin.rowsByName.keyset() );
		allRows.addAll( subtractCard.tableForJoin.rowsByName.keySet() );
		for( String rowName : allRows )
		{
			Row subtractFromRow = subtractFromCard.tableForJoin.rowsByName.get( rowName );
			Row subtractRow = subtractCard.tableForJoin.rowsByName.get( rowName );
			Row comparedRow;
			if( subtractFromRow != null )
			{
				comparedRow = new Row( rowName, subtractFromRow.rowType );
				Set<String> allColumns = new Set<String>( subtractFromRow.columnMap.keySet() );
				if( subtractRow != null )
					allColumns.addAll( subtractRow.columnMap.keySet()  );
				for( String colName : allColumns )
				{
					Decimal subtractValue = 0;
					Decimal subtractFromValue = 0;
					if( subtractRow != null && subtractRow.columnMap.containsKey( colName ) )
					{
						subtractValue = subtractRow.columnMap.get( colName ).value;
						subtractValue = subtractValue == null ? 0 : subtractValue;
					}
					if( subtractFromRow != null && subtractFromRow.columnMap.containsKey( colName  ) )
					{
						subtractFromValue = subtractFromRow.columnMap.get( colName ).value;
						subtractFromValue = subtractFromValue == null ? 0 : subtractFromValue;
					}
					Decimal cellValue = subtractFromValue - subtractValue;
					Cell comparedCell = new Cell(colName, cellValue);
					comparedRow.addColumn( comparedCell );				
				}
			}
			else
			{
				comparedRow = new Row( rowName, subtractRow.rowType );
				for( String colName : subtractRow.columnMap.keySet() )
				{
					Decimal cellValue = -subtractRow.columnMap.get( colName ).value;
					comparedRow.addColumn( new Cell( colName, cellValue ) );
				}	
			}

			comparator.tableForJoin.addRow( comparedRow );
		}
		return comparator;
	}

	public void run()
	{
		for(Title t : titles[lastTitleLayer])
		{
			t.table.initializeCells();//initializeJoinTableCells( );
			t.table.executeQueries();
/*			tableForJoin.initializeJoinTableCells( );
			tableForJoin.fillCellValues( );*/
		}
	}

	public class GlobalCondition
	{
		public transient JoinerTable mainTable { get; private set; }
		public transient List<RollupField> conditions { get; private set;}
		public transient String nonJoiningConditions { get; private set;}

		public GlobalCondition( JoinerTable mainTable )
		{
			this.mainTable = mainTable;
			conditions = new List<RollupField>();
			nonJoiningConditions = '';
		}

		public GlobalCondition onCondition(RollupField field)
		{
			conditions.add( field );
			return this;
		}

		public GlobalCondition andCondition(String condition)
		{
			nonJoiningConditions += ' and ' + condition;
			return this;
		}

		public GlobalCondition andCondition(RollupField field)
		{
			conditions.add( field );
			return this;
		}

		public String getCondition(String tableName)
		{
			String condition = '';
			if(mainTable.results.size() > 0)
			{
				condition = '(';
				for(sObject result : mainTable.results)
				{
					String innerCondition = '';
					String value;
					for(RollupField field : conditions)
					{
						Object res = result.get( field.aliasName );
						String joiningTableFieldName = field.getTableFieldName( tableName );
						if( res != null )
						{
							if( res instanceOf String )
							{
								innerCondition += joiningTableFieldName + '=\'' + String.valueOf( res ) + '\' and ';
							}
							else if( res instanceOf DateTime )
							{
								innerCondition += joiningTableFieldName + '=' + String.valueOf( ((DateTime)res).dateGmt() ) + ' and ';
							}
							else if( res instanceOf Integer )
							{
								innerCondition += joiningTableFieldName + '=' + res;
							}
							else
							{
								System.assert( false, 'Unimplemented type for this thing: ' + tableName + '.' + joiningTableFieldName );
							}
						}
					}

					innerCondition = innerCondition.removeEnd( 'and ' );
					
					if( innerCondition != '' )
					{
						condition += '(' + innerCondition + ')';
						condition += ' or ';
					}
					
				}
				condition = condition.removeEnd( ' or ');
				condition += ')';
			}
			if( condition == '()' && nonJoiningConditions == '')
				return '';
			return condition + nonJoiningConditions;
		}
	}

	public class JoinerTable
	{
		public transient QueryGroup joinerQuery;

		public List<Row> rows { get; private set;}
		public transient List<QueryGroup> queryGroups { get; private set; }
		public Row grandTotal { get; private set;}
		public Map<String, Row> rowsByName { get; private set;}

		public JoinerTable( QueryGroup joinerQuery )
		{
			this();
			this.joinerQuery = joinerQuery;
		}

		public JoinerTable( QueryGroup joinerQuery, List<SObject> results )
		{
			this( joinerQuery );
			this.results = results;
		}

		public JoinerTable()
		{
			this.rowsByName = new Map<String, Row>();
			grandTotal = new Row('Grand Total', 'grandtotal');
			queryGroups = new List<QueryGroup>();
			rows = new List<Row>();
		}

		public GlobalCondition join( QueryGroup queryGroup )
		{
			GlobalCondition condition = new GlobalCondition( this );
			QueryGroup localQueryGroup = new QueryGroup( queryGroup );
			localQueryGroup.setGlobalCondition( condition );
			queryGroups.add( localQueryGroup );
			return condition;
		}

		public void compareColumns(String goalColumnName, String actualColumnName)
		{
			for(Row r : rows)
			{
				r.checkCellBelowTarget(goalColumnName, actualColumnName);
			}
			grandTotal.checkCellBelowTarget(goalColumnName, actualColumnName);
		}

		public Column createCompareByDivisionColumn(String columnLabel, String cssName, String columnName, String numeratorColumnName, String denominatorColumnName, String colType)
		{
			Column columnHeader = new Column.ColumnHeader(columnName, columnLabel, cssName, colType);
			for(Row r : rows)
			{
				Cell c = createCompareByDivisionCell(r, columnName, numeratorColumnName, denominatorColumnName, colType);
				r.addColumn( c );
			}
			Cell c = createCompareByDivisionCell(grandTotal, columnName, numeratorColumnName, denominatorColumnName, colType);
			grandTotal.addColumn( c );

			return columnHeader;
		}

		public void fillEmptyColumn( Column emptyCol )
		{
			for( String rowName : rowsByName.keySet() )
			{
				Row r = rowsByName.get( rowName );
				r.addColumn( new Cell( emptyCol.name, null) );
			}
		}

		public void addRow( Row r )
		{
			if( !rowsByName.containsKey( r.Name ) )
			{
				rows.add( r );
				rowsByName.put( r.name, r );
			}
		}
		
		public Row createOtherRow(String rowName )
		{
			return createOtherRow(rowName, rows);
		}

		public Row createOtherRow(String rowName, List<Row> rowsToCount)
		{
			Row otherRow = new Row( rowName, '' );
			Map<String, Decimal> colNameToTotal = new Map<String, Decimal>();
			
			for( Row r : rowsToCount )
			{
				mapRowsCellsTotal( r, colNameToTotal );
			}

			Map<String, Decimal> colNameToGrandTotal = new Map<String, Decimal>();
			mapRowsCellsTotal( grandTotal, colNameToGrandTotal );
			
			for( String colName : colNameToTotal.keySet() )
			{
				Decimal rowsTotal = colNameToTotal.get( colName );
				Decimal grandTotal = colNameToGrandTotal.get( colName );
				Decimal diff = grandTotal - rowsTotal;
				
				otherRow.addColumn( new Cell(colName, diff) );
			}
			return otherRow;
		}

		private void mapRowsCellsTotal( Row r, Map<String, Decimal> colNameToTotal )
		{
			for( String colName : r.columnMap.keySet() )
			{
				Decimal colsValue = r.columnMap.get(colName).value;
				if( !colNameToTotal.containsKey( colName ) )
				{
					colNameToTotal.put( colName, 0 );
				}
				colNameToTotal.put( colName, colNameToTotal.get(colName) + colsValue );
			}			
		}

		public Column createPercentageColumn(String headerName, String cssName, String columnCounter)
		{
			Column columnHeader = new Column.ColumnHeader(headerName, headerName, cssName, Column.PERCENT_TYPE);
			Decimal grandTotalCellValue = grandTotal.columnMap.get( columnCounter ).value;
			for(Row r : rows)
			{
				if(grandTotalCellValue == 0)
					r.addColumn( new Cell(headerName, 0) );
				else
					r.addColumn( new Cell(headerName, (r.columnMap.get(columnCounter).value / grandTotalCellValue) * 100) );
			}
			grandTotal.addColumn( new Cell(headerName, 100));
			return columnHeader;
		}

		private Cell createCompareByDivisionCell(Row r, String columnName, String numeratorColumnName, String denominatorColumnName, String colType)
		{
			Decimal numerator = r.columnMap.get( numeratorColumnName ).value;
			Decimal denominator = r.columnMap.get( denominatorColumnName ).value;
			Decimal value;
			if(denominator == null || denominator == 0 || numerator == null)
			{
				value = 0;
			}
			else
			{
				value = (numerator/denominator);
				if( colType == Column.PERCENT_TYPE )
				{
					value = value * 100;
				}	
			}
			 return new Cell(columnName, value);
		}

		public void initializeJoinTableCells()
		{
			List<RollupField> rollupFields = joinerQuery.rollup.rollupFields;
			for(sObject table : results)
			{ // after initialization, I should know all the possible groupings
				for(RollupField field : rollupFields)
				{
					String fieldValue = String.valueOf( table.get(field.aliasName) );
					if( fieldValue != null && !rowsByName.containsKey(fieldValue) )
					{
						Row r = new Row( fieldValue, field.aliasName );
						rowsByName.put( fieldValue, r );
						rows.add(r);
						initializeCells( r );
					}
				}
			}
			initializeCells( grandTotal );
		}

		public void fillCellValues()
		{
			List<RollupField> rollupFields = joinerQuery.rollup.rollupFields;
			for( QueryGroup queryGroup : queryGroups )
			{
				String query = queryGroup.getQuery();
				List<AggregateResult> results;
				try
				{
					results = Database.query( query );
				}
				catch(Exception e)
				{
					System.assert( false, 'it failed! ' + query );
				}

				for( AggregateResult result : results )
				{
					Map<String, Cell> cells = queryGroup.getValues( result );
					boolean isGrandTotalRow = true;
					for(Integer i = rollupFields.size()-1; i >= 0; i--)
					{
						RollupField field = rollupFields.get(i);
						String rowName = String.valueOf( result.get(field.aliasName) );
						if(rowName != null)
						{
							System.debug('what is null?' + rowName);
							Row r = rowsByName.get(rowName);
							if(r != null)
								r.addColumns( cells );
							isGrandTotalRow = false;
							break;
						}
					}
					if(isGrandTotalRow)
					{
						grandTotal.addColumns( cells );
					}
				}
			}
		}

		public void initializeCells( Row rowToInitialize )
		{
			for( QueryGroup queryGroup : queryGroups )
			{
				rowToInitialize.addColumns( queryGroup.getInitialValues() );
			}
		}

		public List<sObject> results
		{
			get
			{
				if(results == null)
				{
					results = Database.query( joinerQuery.getQuery() + ' ORDER BY ' + joinerQuery.rollup.getGroupByStatement(joinerQuery.objectType) );
				}
				return results;
			}
			private set;
		}
	}

	public class RollupField
	{
		public transient Map<String, String> tableNameToFieldName;
		public transient String aliasName { get; private set;}

		public RollupField(String aliasName)
		{
			this.aliasName = aliasName;
			tableNameToFieldName = new Map<String, String>();
		}

		public String getTableFieldName(String tableName)
		{
			return tableNameToFieldName.get(tableName);
		}

		public RollupField putTableToField(String tableName, String tableFieldName)
		{
			tableNameToFieldName.put(tableName, tableFieldName);
			return this;
		}
	}

	public class Rollup
	{
		public transient List<RollupField> rollupFields {get; private set;}

		public Rollup()
		{
			rollupFields = new List<RollupField>();
		}

		public Rollup( Rollup copyFrom )
		{
			rollupFields = new List<RollupField>(copyFrom.rollupFields);
		}

		public RollupField findRollupField(String rollupFieldName)
		{
			for(RollupField rollupField : rollupFields)
			{
				if(rollupField.aliasName == rollupFieldName)
					return rollupField;
			}
			return null;
		}

		public void addRollupField(RollupField rollupField)
		{
			rollupFields.add( rollupField );
		}

		public RollupField addRollupField( String rollupFieldName )
		{
			RollupField rollupField = new RollupField( rollupFieldName );
			rollupFields.add( rollupField );
			return rollupField;
		}

		public String getRollupFields(String tableName)
		{
			String rollupFieldsToReturn = '';
			for(RollupField rollupField : rollupFields)
			{
				rollupFieldsToReturn += rollupField.getTableFieldName(tableName) + ' ' + rollupField.aliasName + ', ';
			}
			rollupFieldsToReturn = rollupFieldsToReturn.removeEnd(', ');
			return rollupFieldsToReturn;
		}

		public String getGroupByStatement(String tableName)
		{
			String groupByStatement = '';
			for(RollupField rollupField : rollupFields)
			{
				groupByStatement += rollupField.getTableFieldName(tableName) + ', ';
			}
			groupByStatement = groupByStatement.removeEnd(', ');
			return groupByStatement;
		}
	}
}