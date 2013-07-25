public virtual class Table
{
	public List<QueryGroup> queries;
	public Row myRow {get{ if( myRow == null ) myRow = new Row('myRow', ''); return myRow; } private set;}

	public Table()
	{
		myRow = new Row('myRow', '');
		queries = new List<QueryGroup>();
	}

	public Scorecard.GlobalCondition add( QueryGroup query )
	{
		Scorecard.GlobalCondition condition = new Scorecard.GlobalCondition(null);
		QueryGroup localQuery = new QueryGroup( query );
		queries.add( localQuery );
		localQuery.setGlobalCondition( condition );
		return condition;
	}

	public virtual void initializeCells()
	{
		for( QueryGroup queryGroup : queries )
		{
			Map<String, Cell> c = queryGroup.getInitialValues();
			if( c != null )
			{
				myRow.addColumns( c );
			}
		}
	}

	public virtual void executeQueries()
	{
		for( QueryGroup query : queries )
		{
			String strQuery = query.getQuery();
			System.debug('what is the query?' + strQuery );
			List<AggregateResult> results;
			try
			{
				if( String.isBlank( strQuery ) ) return;
				results = Database.query( strQuery );
			}
			catch(Exception e)
			{
				System.assert(false, 'Invalid query! ' + strQuery + ':' + query.objectType + ':' +  e );
				return;

			}
			for( AggregateResult result : results )
			{
				Map<String, Cell> cells = query.getValues( result );

				for( Column col : query.columns )
				{
					if( cells.containsKey( col.name ) )
					{
						Cell c = cells.get( col.name );
						myRow.addColumn( c );
					}
				}
			}
		}
	}

/*	public virtual void invertCellPercentageColoring( List<String> colNames)
	{
		for( String colName : colNames )
		{
			if( myRow.columnMap.containsKey( colName ) )
			{
				Cell c = myRow.columnMap.get( colName );
				c.invertPercentageColoring();
			}
		}
	}*/

	public virtual void fillEmptyColumn( Column emptyCol )
	{
		myRow.addColumn( new Cell( emptyCol.name, null) );
	}

	public virtual Column createCompareByDivisionColumn(String columnLabel, String cssName, String columnName, String numeratorColumnName, String denominatorColumnName, String colType)
	{
		Column columnHeader = new Column.ColumnHeader(columnName, columnLabel, cssName, colType);
		Cell c = createCompareByDivisionCell(myRow, columnName, numeratorColumnName, denominatorColumnName, colType);
		myRow.addColumn( c );
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

	public class JoinerTable extends Table
	{
		public transient QueryGroup joinerQuery;

		public transient List<Row> rows;
		public transient List<QueryGroup> queryGroups { get; private set; }
		public Row grandTotal { get; private set; }
		public Map<String, Row> rowsByName {get; private set;}

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
			grandTotal = new Row('Grand Total', 'grandtotal');
			queryGroups = new List<QueryGroup>();
			rows = new List<Row>();
			rowsByName = new Map<String, Row>();
		}

/*		public Scorecard.GlobalCondition join( QueryGroup queryGroup )
		{
			Scorecard.GlobalCondition condition = new Scorecard.GlobalCondition( this.results );
			QueryGroup localQueryGroup = new QueryGroup( queryGroup );
			localQueryGroup.setGlobalCondition( condition );
			queryGroups.add( localQueryGroup );
			return condition;
		}*/

		public void compareColumns(String goalColumnName, String actualColumnName)
		{
			for(Row r : rows)
			{
				r.checkCellBelowTarget(goalColumnName, actualColumnName);
			}
			grandTotal.checkCellBelowTarget(goalColumnName, actualColumnName);
		}

		public override Column createCompareByDivisionColumn(String columnLabel, String cssName, String columnName, String numeratorColumnName, String denominatorColumnName, String colType)
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

		public override void fillEmptyColumn( Column emptyCol )
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

		public override void initializeCells()
		{
			List<Scorecard.RollupField> rollupFields = joinerQuery.rollup.rollupFields;
			for(sObject table : results)
			{ // after initialization, I should know all the possible groupings
				for(Scorecard.RollupField field : rollupFields)
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

		public override void executeQueries()
		{
			List<Scorecard.RollupField> rollupFields = joinerQuery.rollup.rollupFields;
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
						Scorecard.RollupField field = rollupFields.get(i);
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
}