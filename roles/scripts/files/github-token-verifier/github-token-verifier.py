import requests


def inspect_github_token(github_token: str):
    headers = {"Authorization": f"token {github_token}", "Accept": "application/vnd.github+json"}

    # Check if token is valid and identify type
    user_resp = requests.get("https://api.github.com/user", headers=headers)
    if user_resp.status_code == 401:
        print("Invalid or expired token.")
        return

    # Fine-grained tokens respond with installation info
    app_resp = requests.get("https://api.github.com/app", headers=headers)
    if app_resp.status_code == 200:
        print("Token Type: Fine-Grained Personal Access Token (FGPAT)")
        permissions_resp = requests.get("https://api.github.com/user/permissions", headers=headers)
        if permissions_resp.status_code == 200:
            print("Permissions:")
            for perm, level in permissions_resp.json().items():
                print(f"- {perm}: {level}")
        else:
            print("Unable to retrieve permissions for fine-grained token.")
        return

    # Classic PAT fallback
    print("Token Type: Classic Personal Access Token (PAT)")
    scopes = user_resp.headers.get("X-OAuth-Scopes", "")
    print("Scopes:", scopes if scopes else "No scopes found or limited visibility.")


if __name__ == "__main__":
    token = input("Enter your GitHub token: ").strip()
    inspect_github_token(token)
