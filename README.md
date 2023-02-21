## Tririga Application Suite (TAS) - Automated

The following script and steps have been adopted from the officially [published documentation](https://www.ibm.com/docs/en/tas/11.2?topic=installing-tririga-application-suite-components). 

Author: Arif Ali (aali@us.ibm.com)

### 1. Get Started with the OpenShift CLI

1.1. Click **OpenShift web Console** button. From the top-right corner, drop-down your **account name** and select **Copy login command** (this opens a new tab). From the newly opened browser tab, click **Display Token** link. Copy the entire line from the **Log in with this token**. Paste on terminal and hit **Enter**.

### 2. Getting access to IBM container images (entitled software)

2.1. Locate your IBM entitlement registry key from the [My IBM Container Software Library](https://myibm.ibm.com/products-services/containerlibrary). Insert your long string key in `env.sh` (line number 11). Save the file (Ctrl+s).

### 3. Running IBM Cloud Pak® for Data

⏰ Estimated time: 1+ hour.

3.1. Run `cd tridata112; ./cpd.sh`

3.2. Interactively create the DB2 Warehouse Database instance

⏰ Estimated time: 15+ minutes.

3.2.1. From the **Networking -> Routes** section of the OpenShift's Web Console, drop-down the Projects field and select `ibm-cpd` project.  Click to launch the **cpd** URL (link is in the **Location** column). Accept the self-signed certificate warning. The **username** is `admin`. 

3.2.2. Locate the password from the **Worksloads -> Secrets** section of the OpenShift web console. The **secret name** containing the password is: `admin-user-details`. The password is located under **Data** section (scroll down). Click on **Reveal values** link to reveal the password under: `initial_admin_password`. Copy the password.

3.3. Log in to Cloud Pak for Data Web Console.

3.3.1. From the hamburger menu, drop-down **Services**. Click on **Services catalog**. Search `db2w` and click the tile. Click **Provision instance** button.

3.4. Using the following matrix, create your database instance:

Value | Key
---|---
TASDB | Database Name
10 | CPU per node for Db2 Warehouse
42 | Memory per node for Db2 Warehouse  
Unchecked | Deploy database on dedicated nodes
Single location for all data | Storage Structure   
Checked | 4K Sector Size   
Checked | Oracle compatibility   
Operational Analytics | Workload  
ibmc-file-gold-gid | Storage class   
500 GiB | Size  

3.5. Create tridata/tridata user account and assign to the instance

3.5.1. From the hamburger menu, select **Administration - Access control**. Click **Add user** button. Create username: `tridata` with the password: `tridata`. Click Next. Select **Assign roles directly**. Click Next. Select **User** checkbox as a **Roles**. Click Next. Click **Add**.

3.5.2. From the hamburger menu, select **Services - Instances**. Click on the three-dot menu of the Db2 Warehouse-1 instance and select **Manage access**. Click the **Add users** button. Select **tridata** and choose **Admin** Role. Click **Add** button.

3.6. Locate DB2's Instance ID

3.6.1. From the hamburger menu, select **Services - Instances**. Click on the **DB2 Warehouse-1** instance. Copy the randomly generated numbered ID from the **Deployment id** field (do not copy the word `db2wh`. Only copy the randomly generated numbers).

3.6.2. Update `env.sh` with DB2W unique ID (line number 15). Save the env.sh file.

3.7. Create Database

⏰ Estimated time: 5-7 minutes.

3.7.1. Run `./db2wh.sh`

### 4. Acquiring Tririga AppPoint License

4.1. Copy license to /manifests/slsbootstrap.yaml

### 5. Set up TAS dependencies

⏰ Estimated time: 45 minutes.

5.1. Run `./dependencies.sh`

### 6. Running Tririga Application Suite

⏰ Estimated time: 2-3 hours.

6.1. Run `./tas.sh`

---

system/admin (/tririga/index.html)

