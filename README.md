# linkding fly.io Setup

This repository provides an application setup for running a linkding application on [fly.io](https://fly.io).

fly.io is a developer-centric hosting service for Docker images. fly.io is straightforward to use and has reasonable pricing. For running a personal linkding instance you should be good with the resources provided by the free tier, except for storage which is needed for persisting your linkding database through application restarts. The minimum amount of storage you can buy is 10GB, which is currently 1.50$ / month according to their [pricing](https://fly.io/docs/about/pricing/).

This setup is currently intended for technical audiences only. You need to able use the command line and setup developer specific tools. No support will be provided in this repo, other than issues with the setup itself (bugfixes + improvements).

**NOTE that you need a credit card** in order to use their service, in case your applications exceeds the resources provided in the free tier. Check their [pricing page](https://fly.io/docs/about/pricing) for details. Make sure to check regularly on your applications actual resource usage.

## Prerequisites
The following software needs to be available on your system to use this setup:
- Git
- Docker

## Install fly.io CLI

fly.io provides a command line tool for interacting with their service. See here for installation instructions: https://fly.io/docs/getting-started/installing-flyctl/

## Signup or login

Run the following command to sign up for a free account:
```
flyctl auth signup
```
*NOTE: This will require a valid credit card in case your application will exceed the free plan. Check their [pricing page](https://fly.io/docs/about/pricing) for details.*

Alternatively if you already have an existing fly.io account then login with:
```
flyctl auth login
```

## Application setup

Clone this repository to get an initial setup:
```
git clone git@github.com:sissbruecker/linkding-fly-io.git
```
Navigate into the directory:
```
cd linkding-fly-io
```
Create a new fly.io app:
```
flyctl launch
```
Answer the required questions such as in which region the application should run. Do **NOT** deploy the application yet.

## User setup

This setup will create an initial linkding admin user when the application is deployed. In order to do that you need to provide an initial username and a password for the deployment:
```
flyctl secrets set LINKDING_USER_NAME=<user-name> LINKDING_USER_PASS=<user-password>
```
Replace `<user-name>` and `<user-password>` with the credentials that you would like to use.

## Storage setup

In order for your database to be persisted across application restarts you need to setup a volume on which the database is stored. **As stated in the intro this is a commercial feature outside of the free tier which you have to pay for.**

To create a volume, run:
```
fly volumes create linkding_data --region=<region> --size 10
```
This will create a volume with a size of 10GB, which is currently the minimum that you can use.
Note that the volume needs to be created  in a specific region. You should enter the same region that you picked when running `flytcl launch`. You can see a list of all regions [here](https://fly.io/docs/reference/regions/).

## Application configuration

Edit `fly.toml` and replace everything below the `app = ...` line with:
```
kill_signal = "SIGINT"
kill_timeout = 5

[[services]]
  internal_port = 9090
  protocol = "tcp"

  [services.concurrency]
    hard_limit = 1000
    soft_limit = 1000

  [[services.ports]]
    handlers = ["http"]
    port = "80"

  [[services.ports]]
    handlers = ["tls", "http"]
    port = "443"

  [[services.tcp_checks]]
    grace_period = "1s"
    interval = "15s"
    port = "9090"
    restart_limit = 6
    timeout = "2s"

[mounts]
source="linkding_data"
destination="/etc/linkding/data"
```
The concurrency is intentionally set to a high number to prevent unexpected spawning of additional instances which might result in additional costs.

## Run the application

To deploy the application run:
```
flyctl deploy
```

This will:
- build a custom Docker image based on the latest linkding image
- upload it to the fly.io container registry
- create a release for your application

To get information about your running application, such as under which hostname it is deployed, run:
```
flyctl info
```
Alternatively you can also view your running app through the fly.io web dashboard: https://fly.io/apps/. In general check their docs on how to interact with your application: https://fly.io/docs/.

If you open the URL for your deployed application in the browser, you should see the linkding login view. You can login using the credentials that you have set in the previous step. If you need to change the password open the linkding settings and click on the Admin link to open the admin application. You can change your password here or create additional users if needed.

## Delete the application

If you don't want to use the service anymore you can delete the application by running:
```
flyctl destroy <app-name>
```
Where `<app-name>` is the name that was generated for your fly.io application (see `fly.toml`). This will delete your app, not undeploy it. If you want to stop deployments check the [suspend](https://fly.io/docs/flyctl/apps-suspend/#welcome-message) command.

## Custom domain name

By default your application will be deployed under a generic `<app-name>.fly.dev` domain. If you want to use a custom domain you can register a custom domain with any domain registrar and then set up a CNAME that points to your fly.dev domain. fly.io has more information in their docs on how to do that: https://fly.io/docs/getting-started/working-with-fly-apps/#fly-and-custom-domains
