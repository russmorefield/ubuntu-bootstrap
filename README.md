# Ubuntu Bootstrap Master Script

This repository contains a comprehensive master script, `ubuntu-bootstrap.sh`, designed to automate the initial setup and configuration of a new Ubuntu server. It consolidates several common administrative tasks into a single, interactive, menu-driven utility.

The primary goal of this script is to create a secure, modern, and developer-friendly environment quickly and consistently across multiple machines.

---

## Features

This script provides a modular, menu-based interface to perform the following actions:

### Initial Server Setup:

- Creates a new user with `sudo` privileges.
- Configures passwordless `sudo` for the new user.
- Fetches a public SSH key from a specified GitHub user profile and adds it to the new user's `authorized_keys` file for immediate, secure access.
- Creates a `/home/<user>/docker` directory for organizing container projects.
- Adds the new user to the `docker` group.

### SSH Hardening:

- Disables root login via SSH.
- Disables password-based authentication, enforcing key-only access.
- Restricts SSH access to the newly created user via the `AllowUsers` directive.

### Oh My Posh Installation:

- Installs the Oh My Posh shell theme engine.
- Installs the recommended "Caskaydia Cove Nerd Font".
- Configures the user's `.bashrc` to use the "Catppuccin" theme.

### Docker Installation:

- Installs Docker Engine and Docker Compose using the official Docker repository.
- Adds the current user to the `docker` group to allow running Docker commands without `sudo`.

### System Discovery:

- Runs a non-intrusive discovery report on script startup to provide a baseline of the server's hardware and software configuration.
- Saves the report to a log file in `/tmp`.

---

## Usage

This script is designed to be run on a **fresh Ubuntu server instance**. You should be logged in as the **root user**, which is standard for most cloud providers' initial setup.

To execute the script, run the following one-line command. This will download the script from this repository and execute it with `sudo` privileges.

> Replace `YourUsername` with your actual GitHub username.

```bash
curl -sL "https://raw.githubusercontent.com/russmorefield/ubuntu-bootstrap/main/ubuntu-bootstrap.sh" | sudo bash
```

---

## Workflow

1. Run the command above on your new server.
2. A System Discovery report will run automatically, giving you an overview of the machine.
3. The main menu will appear.
4. Select **Option 1** to perform the initial user creation and server hardening. You will be prompted for:
   - The new username you want to create (e.g., `russ`)
   - The GitHub username whose public SSH keys you want to authorize (e.g., `russmorefield`)
5. After the initial setup is complete, restart the SSH service:

```bash
sudo systemctl restart sshd
```

6. Log in as the new user from a separate terminal to confirm access.
7. You can then run the script again (`sudo /path/to/script` if saved, or re-run the `curl` command) to install Docker, Oh My Posh, or perform other tasks as the new user.

---

## Security Note

The script fetches public SSH keys from a public GitHub URL. This is a secure operation because:

- **Authentication is required before running the script**: Only a user who is already authenticated as root on the server can execute this script.
- **Public keys are designed to be public**: They cannot be used to impersonate you. They can only be used to grant access.
- **Only an authorized user can grant access**: The script uses the root privileges (from the initial login) to place the public keys into the `authorized_keys` file, which is a privileged action.
