@isTest
private class TestTitle
{
	static testMethod void testBuildDynamicTitles()
	{
		Test.startTest();
			List<Title> titles = Title.buildDynamicTitles( 'Account', 'Rating' );
		Test.stopTest();
		System.assertEquals( 3, titles.size(), 'Each picklist value should be mapped' );
		System.assertEquals( 'Hot', titles[0].label, '' );
		System.assertEquals( 'Warm', titles[1].label, '' );
		System.assertEquals( 'Cold', titles[2].label, '' );
	}
}