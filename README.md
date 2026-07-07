# item_purchase_tool_site

A full-stack Salesforce Lightning Web Component (LWC) application designed to modernize the internal item purchasing experience. This tool transforms a standard Account record page into a dynamic e-commerce storefront, allowing authorized users to browse inventory, filter items, and process checkouts directly within Salesforce.

## Key Features

* **Custom LWC Frontend:** A responsive, grid-based UI built with the Salesforce Lightning Design System (SLDS).
* **Dynamic Cart Management:** Users can add items, review quantities, and checkout via an interactive modal.
* **Automated Inventory & Math:** Apex Triggers automatically deduct inventory counts and calculate order totals (Grand Total & Total Items) in real-time.
* **Unsplash API Integration:** Automatically fetches dynamic, real-world images for newly created items based on their name.
* **Role-Based Security:** Features custom Field-Level Security and backend checks to ensure only authorized "Manager" users can create new items in the database.

## Tech Stack

* **Frontend:** Lightning Web Components (LWC), JavaScript, HTML, CSS, SLDS
* **Backend:** Apex (Controllers, Triggers, Mock Callouts), SOQL, REST API Integration
* **Database:** Salesforce Custom Objects (`Item__c`, `Purchase__c`, `PurchaseLine__c`)

## Installation

You can install this entire project (including all code, objects, and configurations) directly into your Salesforce Developer Org using the Unmanaged Package link below:

**Install Here:** [https://login.salesforce.com/packaging/installPackage.apexp?p0=04tdL000000hgYf]
