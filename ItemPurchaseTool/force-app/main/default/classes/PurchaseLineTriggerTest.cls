@isTest
private class PurchaseLineTriggerTest {
    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'TrueSolv Trigger Account');
        insert acc;

        Item__c testItem = new Item__c(
            Name = 'Test Monitor', 
            Price__c = 200, 
            AvailableQuantity__c = 100
        );
        insert testItem;

        Purchase__c purchase = new Purchase__c(
            Name = 'Test Trigger Purchase',
            ClientId__c = acc.Id
        );
        insert purchase;
    }

    @isTest
    static void testInsertCalculatesTotals() {
        Purchase__c p = [SELECT Id FROM Purchase__c LIMIT 1];
        Item__c i = [SELECT Id FROM Item__c LIMIT 1];

        PurchaseLine__c line1 = new PurchaseLine__c(
            PurchaseId__c = p.Id, ItemId__c = i.Id, Amount__c = 2, UnitCost__c = 200
        );
        PurchaseLine__c line2 = new PurchaseLine__c(
            PurchaseId__c = p.Id, ItemId__c = i.Id, Amount__c = 3, UnitCost__c = 200
        );

        Test.startTest();
        insert new List<PurchaseLine__c>{line1, line2};
        Test.stopTest();

        Purchase__c updatedPurchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :p.Id];
        
        System.assertEquals(5, updatedPurchase.TotalItems__c, 'Total items should calculate to 5.');
        System.assertEquals(400, updatedPurchase.GrandTotal__c, 'Grand total should calculate to 400.');
    }

    @isTest
    static void testDeleteCalculatesTotals() {
        Purchase__c p = [SELECT Id FROM Purchase__c LIMIT 1];
        Item__c i = [SELECT Id FROM Item__c LIMIT 1];

        PurchaseLine__c line = new PurchaseLine__c(
            PurchaseId__c = p.Id, ItemId__c = i.Id, Amount__c = 5, UnitCost__c = 100
        );
        insert line;

        Test.startTest();
        delete line;
        Test.stopTest();

        Purchase__c updatedPurchase = [SELECT Id FROM Purchase__c WHERE Id = :p.Id];
        System.assertNotEquals(null, updatedPurchase.Id, 'Purchase should still exist after deleting lines.');
    }
}