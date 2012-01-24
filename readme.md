# About
The purpose of this project is to allow developers to locally develop against Amazon's DynamoDB. This is achieved by emulating DynamoDB via MongoDB.

## Usage
At this time, and very uselessly, only `CreateTable`, `ListTables` and `DeleteTable` are supported. Support for query/update/delete/insert operations will be done in the next few days.

Configuration can be set by changing `config.js`. The `server` section indicates what host/port the server should listen on. The `db` section is the MongoDB information.

You should configure your application to connect to your locally running alternator project rather than the Amazon EC2 DynamoDB instance. This varies from driver to driver. In C#, you'd do:

	private static void CreateClient()
	{
  		AmazonDynamoDBConfig config = new AmazonDynamoDBConfig();
  		config.ServiceURL = "http://127.0.0.1/";
  		client = new AmazonDynamoDBClient(config);
	}     

Until `.js` files are provided (once this thing isn't completely useless), you can start the server via `coffee app.coffee`.

## Errors
By far the trickiest part to emulate will be the possible errors and other edge-cases. Hopefully the story will get better with time. As of now, we do try to handle the basic, such as creating a table which already exists, deleting a table which doesn't exist, and input validation.