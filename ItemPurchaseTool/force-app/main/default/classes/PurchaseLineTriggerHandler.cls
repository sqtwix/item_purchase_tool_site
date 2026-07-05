public with sharing class PurchaseLineTriggerHandler {
    public static void calculatePurchaseTotals(List<PurchaseLine__c> newLines) {
        // Collect all parent Purchase IDs that need to be recalculated
        Set<Id> purchaseIds = new Set<Id>();
        for (PurchaseLine__c line : newLines) {
            if (line.PurchaseId__c != null) {
                purchaseIds.add(line.PurchaseId__c);
            }
        }

        if (purchaseIds.isEmpty()) return;

        // Query the database to get the SUM of Amount and (Amount * UnitCost) using AggregateResult
        List<AggregateResult> results = [
            SELECT PurchaseId__c, SUM(Amount__c) totalItems, SUM(UnitCost__c) totalCost
            FROM PurchaseLine__c
            WHERE PurchaseId__c IN :purchaseIds
            GROUP BY PurchaseId__c
        ];

        List<Purchase__c> purchasesToUpdate = new List<Purchase__c>();
        
        for (AggregateResult ar : results) {
            Purchase__c p = new Purchase__c();
            p.Id = (Id) ar.get('PurchaseId__c');
            p.TotalItems__c = (Decimal) ar.get('totalItems');
            p.GrandTotal__c = (Decimal) ar.get('totalCost'); 
            
            purchasesToUpdate.add(p);
        }

        if (!purchasesToUpdate.isEmpty()) {
            update purchasesToUpdate;
        }
    }
}