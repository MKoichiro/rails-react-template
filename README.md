# Template: Docker x Rails x PostgreSQL x React x TypeScript

## OUTLINE
### Composition of technology used
#### Development
- Backend: Rails API
- DBMS: PostgreSQL
- Frontend: React
  - Bundler: vite
  - Web server: vite server
  - Type check: tsc
  - Compiler: swc
#### Production
Nginx is adopted for web server instead of vite server.

### Docker-related directory structure
- `./api`
    
    Rails API project

- `./db`
    
    DB with PostgreSQL for dev

- `./web`

    React x TS project

- `./template`

    Templates for recovery in case the project needs to be restarted.
    These are typically not required once development has begun.
```
project_root/
├── api/
│     └── docker/Dockerfile ...etc
├── db/
│     └── docker/
├── web/
│     └── docker/Dockerfile ...etc
├── backup/
│     ├── api/
│     └── web/
├── template/
│     ├── overwrite/
│     └── seed/
├── compose.yml
├── compose.prev.yml
└── compose.prod.yml
```

## Setup Workspace
If you haven't installed "curl" or "unzip" yet, run:
```bash
sudo apt install curl unzip
```

Then, download the Makefile to your workspace:
```bash
cd path/to/your/working/directory/
```
```bash
curl -O https://raw.githubusercontent.com/MKoichiro/rails-react-template/main/Makefile
```

Next, execute the following command to set up the current directory as the Docker Compose context:
```bash
make dcom_context
```

## To establish a test Rails API project
0. You can check the available `make` commands by running:
    ```bash
    make help
    ```


1. Load aliases, by running:
    ```bash
    . ./aliases.sh
    ```
    or
    ```bash
    source ./aliases.sh
    ```
    Now, you can use the command that you run in the next step.
    (Refer to `./aliases.sh` to check default aliases and if necessary, customize them as you like.
    Note that this change is limited to the current shell session.
    If you want to make it permanent, you will need to add the equivalent to `~/.bash_aliases`.)


2. Create `*.env` files and source `./.env`:
    ```bash
    ./generate-env.sh
    . ./.env
    ```
    The command `./generate-env.sh` allows you to set up the required environment interactively. Note that this is defined in `aliases.sh`. This results in the following series of files.
    - `./.env`

        defines environment that will be referred as build args.

    - `./api/docker/api.env`, `./db/docker/db.env`, `./web/docker/web.env`

        define environment that will be used as environment variables in each container.


3. Run `make all-launch`:

    This will execute followings;
    - `bundle exec rails new . --force --skip-bundle --skip-git --database=postgresql --api` in ephemeral api container.
    - `npm create vite@latest -- --template react-swc-ts` in local web directory.

4. Run `make all-setup`

    This will edit following files optimally;
    - ./api/config/database.yml
    - ./web/tsconfig.*.json
    - ./web/vite.config.ts

    Also includes following operations;
    - add rack-cors gem and edit ./api/config/initializers/cors.rb
    - run db:create through api ephemeral container

5. Run `make test-project`

    This will create a simple test project with changes throughout.
    - add users controller, model and db.
    - edit App.tsx to be able to fetch from the api.
    - etc ...
    
    Run `make up` and access to http://localhost:5173

7. Back to step 4

    Run following commands to step back;
    1. `make all-service-clean`
    2. `make all-launch`
    3. `make all-setup`
