## About The Project

This is a sample project with details on how to collect and build a data pipeline using DBT, BigQuery and SQLFluff. I'm also going to cover some hipotetical questions regarding an implemention of a new event pipeline. The topics are divided by hipotetical tasks and you can have more details about them on the next topics of this file. Tasks 1 and 2 were resolve using this  [dataset](https://console.cloud.google.com/marketplace/details/iowa-department-of-commerce/iowa-liquor-sales?filter=solution-type:dataset&filter=category:analytics&id=18f0a495-8e20-4124-a349-0c4c167b60ab&project=my-project-cc-20220626).

## Preview Task (Data Exploration)
Some basic validations were done before developing the queries to answer the questions for task #1. \
These are some important aspects of the source data:
1. There are no duplications, it was tested if it has multiple records for each `invoice_and_item_number`
  ```sql
    select invoice_and_item_number, count(*)
    from bigquery-public-data.iowa_liquor_sales.sales
    group by invoice_and_item_number
    having count(*) > 1
  ```
2. There are some inconsistencies in the dimensions from the stores, I assumed that the `store_number` is the one with more accurate data and used it to make aggregations per store.
  \
  ![Store Name Screen Shot][store_name-screenshot]

3. There are also some inconsistencies on the dimensions from county, also some null records, I assumed the `county` column is the more accurate one as it has less nulls.

## Task #1 (SQL)
(Note - This task aims to test the SQL skills)\
**While using the dataset, please provide SQL queries and their outcome to answer the following questions:**\
1. **Calculate the total products and revenue sold over time by quarter and identify the month where the revenue sold was 10% above the average.**\
  [DBT model](models\reporting\sales\sales_per_quarter.sql)\
  [SQL output](outputs\sales_per_quarter.csv)
2. **List the counties where the amount (in dollars) of purchases transactions went over $100K.**\
  [DBT model](models\reporting\sales\six_figures_counties_revenue.sql)\
  [SQL output](outputs\six_figures_counties_revenue.csv)
3. **Identify the top 10 stores with more revenue in sold products and the bottom stores with least revenue in sold products (apply a deduplication logic in case it’s needed).**\
  [DBT model](models\reporting\sales\top_and_bottom_10_store_revenues.sql)\
  [SQL output](outputs\top_and_bottom_10_store_revenues.csv)

## Task #2 (Data Modeling)
(Note - This task aims to test the data modeling skills. Feel free to use any data modeling techniques)\
**Imagine the provided dataset as a source table in a production database.**
**Please provide a data lineage of the data pipeline and design appropriate data layers for this case. Briefly describe what is the underlying logic of every layer and why you chose it.**


### Staging Layer
The first data layer serves as a repository for raw data within a data warehouse. Typically, only encryption data transformations are applied at this stage. This layer acts as a fallback option in case of errors or discrepancies in downstream stages. \ 

Having a raw data layer benefits pipeline management in several ways, including debugging and auditing capabilities, data recovery, and flexibility for future use cases. It allows for better visibility and control over the data flow and ensures that the data remains intact for future use.

### Intermediate Layer
The intermediate layer has focus in cleaning and adding relevant features to the data. Here, both fact and dimensional data are curated, facilitating their consumption across various reporting.

### Reporting Layer
The reporting layer is the interface for non-technical users and consuptions that will no have other data transformations, the data on it should have user-friendly format for business consumption. At this stage, data can have aggregation operations to align with business granularity requirements. Additionally, joins across different intermediate tables are executed to generate reports with comprehensive information. Common transformations should be avoided at this layer, and moved for the clean data tables in the Intermediate Layer.

### Final Data Lineage
  ![Lineage Screen Shot][lineage-screenshot]

### Structure of Final Tables
#### sales_per_quarter
  ![sales_per_quarter][sales_per_quarter]

#### top_and_bottom_10_store_revenues
  ![top_and_bottom_10_store_revenues][top_and_bottom_10_store_revenues] 
   
  *I’m not including the store dimensions due to the inconsistencies described on “Data Exploration” topic.

#### six_figures_counties_revenue
  ![six_figures_counties_revenue][six_figures_counties_revenue] 
  \
  *I’m not including the store dimensions due to the inconsistencies described in “Data Exploration” topic.

## Task #3 (Event Pipeline)
(Note - This task aims to test data architecture skills.)\
**We experienced some issues when we stored our transactional data in Kafka because we made some previous transformations and our retention policy was short.**
1. **How do you fix this issue? (Please be as descriptive as you can)**
  To begin with, if the Kafka cluster is carrying out data transformations while storing data, I suggest moving them to a separate dedicated processing system such as a data warehouse. Nowadays, several platforms like Snowflake, BigQuery, and Databricks provide efficient and easily manageable stream data transformations.\
  The data ingested in the targets from Kafka should be closer to the raw state and include as much information as possible, thinking not only for current usage but also for future use cases. One way to achieve this is by storing the raw data in storage cloud services like S3 Buckets or Cloud Storage, using performant file formats like parquet and allowing data consumers to access it. This approach offers several benefits, such as long data retention periods at low costs and reliable fallback options for disaster recovery.\
  If the raw data is consumed by a single solution or platform, there are connectors available to ingest the data directly into it. Major data warehouse platforms also provide features like time travel, fail-safe and cost-effective storage options.\
  To transform stream data, we can take advantage of BigQuery built-in capabilities for real-time data processing. BigQuery provides support for continuous streaming ingestion and processing through features such as Dataflow SQL, which allows to perform near-real-time analytics on streaming data. By utilizing BigQuery's scalable infrastructure and SQL-based transformations, it is possible to have an efficiently process and analyze high-velocity data streams, while also benefiting from integration with other Google Cloud services.
   
2. **Imagine you are implementing a new event pipeline:**
  a. **Explain which necessary steps will you include in it**\
    1. Define Data Sources: Identify the sources from which events will be collected, whether they are internal systems, external APIs, or user interactions.
    2. Data Ingestion: Implement mechanisms to ingest data from these sources into the pipeline. This may involve using messaging systems like Kafka, cloud-based services such as Amazon Kinesis, or direct API integrations with python scripts.
    3. Data Transformation: Apply necessary transformations to the raw data to make it usable for downstream processing. This could include cleaning, enrichment, aggregation, or filtering based on business logic.
    4. Data Storage: Determine where and how the processed data will be stored. Options may include data lakes, data warehouses depending on the volume and the target systems.

  b. **At which point of the pipeline will you apply data modeling?**\
    Data modeling should be integrated into every stage of the event pipeline, from the initial raw data ingestion layer to the final reporting data layer.

    Beginning with the raw data layer, it's essential to understand the nature of the data in alignment with the business requirements. This understanding informs decisions regarding necessary metadata extraction from the pipeline and the format of streamed records. For example, considerations include whether to include only new data states or encompass historical records, and whether the loads consist solely of appends or entail other operations.

    As we progress through subsequent pipeline layers, data modeling becomes indispensable for optimizing the flow of information. By structuring the data in a coherent manner, we enhance its comprehensibility for all stakeholders involved.
    
  c. **How would you handle failed events?**
   1. Set up alerts and notifications to identify issues early and take corrective actions before they escalate.
   2. Ensure that data consumers perform data deduplication. In error scenarios, it is common to have the duplication of some streamed records. So it is essential to ensure that downstream consumers are performing any needed data deduplication.
   3. Implement retries. Some errors can be solved just by retrying the operation. If the service interacts with external services, there could be a lot of intermittent errors like network breakdown and call timeout.

## Extra - Describing the Solution
![solution][solution] 
### Data Warehouse – BigQuey
As the source dataset for this case is provided by BigQuery, I also used the platform as a data warehouse.
### Data Transformation Tool – DBT Core
DBT Core is an open source and easy implementation tool that simplifies the tasks of data engineers by supporting in the development, testing, documentation, and version control of data models. Here are some examples and description of DBT features used in this project:\
1. Version control:\
  All SQL scripts have been encapsulated into DBT model files (within the "models" directory), which are managed in this Git repository. This approach enables us to effectively version control the scripts, ensuring traceability and collaboration among team members.

2. Data Quality:\
  DBT provides robust features for data quality testing. We've utilized built-in DBT tests to validate uniqueness and non-null values within the data models (as you can see [here](models\reporting\sales\reporting_sales.yml)). Additionally, a [custom generic test](tests\generic\data_freshness_test.sql) was developed to ensure data freshness.

3. Code Reusability:\
  To streamline development and improve code readability, a [DBT macro](macros\util_macros_data_cleaning.sql) was created to facilitate the replication of transformations across different columns. This enhancement significantly boosts development speed and promotes code consistency throughout the project.

4. Data Lineage:\
  Understanding the lineage of data is crucial for ensuring data accuracy, compliance, and transparency. In this project, we are actively working on establishing comprehensive data lineage using DBT [{{ref}}](https://docs.getdbt.com/reference/dbt-jinja-functions/ref) and [{{source}}](https://docs.getdbt.com/reference/dbt-jinja-functions/source) native functions.

### Linter – SQLFLuff
It was integrated SQLFluff into the project to ensure consistent and standardized SQL code across all our database queries and scripts. By enforcing specific coding standards and best practices, SQLFluff has helped us maintain the readability, reliability, and maintainability of our SQL codebase.

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[store_name-screenshot]: images\store_name_and_number.png
[lineage-screenshot]: images\lineage.png
[top_and_bottom_10_store_revenues]: images\top_and_bottom_10_store_revenues.png
[sales_per_quarter]: images\sales_per_quarter.png
[six_figures_counties_revenue]: images\six_figures_counties_revenue.png
[solution]: images\solution.png