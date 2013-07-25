@isTest
private class TestQueryGroup
{
	static final String ACCOUNT_NUMBER = '1234';
	static final Integer TOTAL_ACCOUNTS = 10;
	static final Integer ACCOUNTS_WITH_SPECIFIC_ACCOUNT_NUMBER = TOTAL_ACCOUNTS - 1;
	static final Integer ANNUAL_REVENUE = 287;
	
	static void setupAccountForQueryGroup()
	{
		List<Account> accounts = new List<Account>();
		for(Integer i = 0; i < TOTAL_ACCOUNTS; i++ )
		{
			accounts.add( new Account( Name='account' + i, AccountNumber=ACCOUNT_NUMBER, AnnualRevenue=ANNUAL_REVENUE ) );
		}
		accounts[0].AccountNumber = ACCOUNT_NUMBER + '0';
		insert accounts;

	}

	static Map<String, Id> columnRecordTypes
	{
		get
		{
			if( columnRecordTypes == null )
			{
				columnRecordTypes = new Map<String, Id>();
				List<RecordType> types = [Select DeveloperName, Id from RecordType where sObjectType='Field__c'];
				for( RecordType type : types )
					columnRecordTypes.put( type.DeveloperName, type.Id );
			}
			return columnRecordTypes;
		}
		private set;
	}
	
	static testMethod void testBuildQueryGroups()
	{
		setupAccountForQueryGroup();
		final String ANNUAL_REVENUE_BY_ACCOUNT_NUMBER = 'conditionalRevenue';
		final String ANNUAL_REVENUE_FOR_OWNER = 'allRevenueByOwner';
		final String ACCOUNT_COUNT = 'accountCount';

		final String CASE_CONDITION = 'AccountNumber=\'' + ACCOUNT_NUMBER + '\'';
		final String STANDARD_CONDITION = 'OwnerId=\'' + UserInfo.getUserId()  + '\''; // need to test this condition too
		Scorecard__c scorecard = new Scorecard__c( Name='myScorecard' );
		insert scorecard;

		QueryGroup__c baQuery = new QueryGroup__c( Name='TestQuery', TableName__c='Account' );
		baQuery.Condition__c = STANDARD_CONDITION;
		insert baQuery;

		List<Row__c> rows = new List<Row__c>();
		rows.add( ScorecardTestingUtils.createRow( scorecard.Id, ANNUAL_REVENUE_BY_ACCOUNT_NUMBER, false) );
		rows.add( ScorecardTestingUtils.createRow( scorecard.Id, ANNUAL_REVENUE_FOR_OWNER, false ) );
		rows.add( ScorecardTestingUtils.createRow( scorecard.Id, ACCOUNT_COUNT, false ) );
		insert rows;

		List<Field__c> fields = new List<Field__c>();
		fields.add( ScorecardTestingUtils.createField( rows[0].Id, baQuery.Id, ScorecardTestingUtils.findRecordType('Field__c', 'Sum').Id, 'AnnualRevenue', CASE_CONDITION, false ) );
		fields.add( ScorecardTestingUtils.createField( rows[1].Id, baQuery.Id, ScorecardTestingUtils.findRecordType('Field__c', 'Sum').Id, 'AnnualRevenue', false ) );
		fields.add( ScorecardTestingUtils.createField( rows[2].Id, baQuery.Id, ScorecardTestingUtils.findRecordType('Field__c', 'Count').Id, 'Id', CASE_CONDITION, false ) );
		insert fields;

		List<QueryGroup__c> queries = [Select TableName__c, Condition__c,
                                              (Select Name, Condition__c, Row__r.Alias__c, RecordType.DeveloperName, API_Name__c from Fields__r)
                                         from QueryGroup__c
                                       where Id = :baQuery.Id];
		Test.startTest();
			List<QueryGroup> builtQueries = QueryGroup.buildQueryGroups( queries );
		Test.stopTest();

		System.assertEquals( 2, builtQueries.size(), 'Distinct Case statments on fields should be considered as unique QueryGroups' );
		List<AggregateResult> queryA = Database.query( builtQueries[0].getQuery() );
		List<AggregateResult> queryB = Database.query( builtQueries[1].getQuery() );

		System.assertEquals( 1, queryA.size(), 'This query was not grouped by anything, so it should only return one row');
		System.assertEquals( 1, queryB.size(), 'This query was not grouped by anything, so it should only return one row');

		Object resultAnnualRevenueByAccountNumber;
		Object resultAccountCount;
		Object resultAnnualRevenueByOwner;
		if( builtQueries[0].columns.size() == 2 )
		{
			resultAnnualRevenueByAccountNumber = queryA[0].get( ANNUAL_REVENUE_BY_ACCOUNT_NUMBER );
			resultAccountCount = queryA[0].get( ACCOUNT_COUNT );
			resultAnnualRevenueByOwner = queryB[0].get( ANNUAL_REVENUE_FOR_OWNER );
		}
		else
		{
			resultAnnualRevenueByAccountNumber = queryB[0].get( ANNUAL_REVENUE_BY_ACCOUNT_NUMBER );
			resultAccountCount = queryB[0].get( ACCOUNT_COUNT);
			resultAnnualRevenueByOwner = queryA[0].get( ANNUAL_REVENUE_FOR_OWNER );
		}
		Decimal revenueForAllMyAccounts = (Decimal)[Select Sum(AnnualRevenue) revenue from Account where OwnerId = :UserInfo.getUserId() ][0].get('revenue');
		AggregateResult queryForMyAccountsWithAccountNumber = [Select Sum(AnnualRevenue) revenue, Count(Id) myAccountCount from Account where OwnerId = :UserInfo.getUserId() and AccountNumber = :ACCOUNT_NUMBER][0];
		Decimal revenueForAllMyAccountsWithAccountNumber = (Decimal)queryForMyAccountsWithAccountNumber.get('revenue');
		Integer countOfMyAccountsWithAccountNumber = (Integer)queryForMyAccountsWithAccountNumber.get('myAccountCount');

		System.assertEquals( revenueForAllMyAccounts, (Decimal)resultAnnualRevenueByOwner, 'The query created via sObject should have summed the the annual revenue for all accounts my accounts with an account number of  ' + ACCOUNT_NUMBER );
		System.assertEquals( revenueForAllMyAccountsWithAccountNumber, (Decimal)resultAnnualRevenueByAccountNumber, 'The query created via sObject should have summed the annual revenue for all my accounts' );
		System.assertEquals( countOfMyAccountsWithAccountNumber, (Integer)resultAccountCount, 'The query created via sObjects should have counted all of the accounts that I own' );
	}
}