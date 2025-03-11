Hi James,

There are no particular application. I basically created two things. One of them is from the assignemnt - Create and send a GetAccept contract from a Salesforce record page.
Then another one is basically a data table contains all documents owned by me, their statuses, dates, etc. Also, there is an ability to create reminders (per your API documentation).
So, you can just open opportunity record page and there in top right corner will be "Create and Send Contract" - this requires to have an opportunity and also a primary contact on that opportunity. Then it should send a document (ContentDocument).
Then in the left bottom corner there will be that data table.

For unit tests object generation i used a publically available repository: https://github.com/benahm/TestDataFactory

Let me know if you have any questions.
Thanks!
