import os
import re

root_folder = r"\\h2m.com\shares\files_shared\WingetUpgradeList-user"

# Prompt for the package Id or Name
search_term = input("Enter the package Id or Name to search for: ").strip().lower()

upgrade_line_pattern = re.compile(
    r"^(?P<Name>.+?)\s+(?P<Id>[^\s]+)\s+(?P<CurrentVersion>[^\s]+)\s+(?P<AvailableVersion>[^\s]+)\s+(?P<Source>[^\s]+)$"
)

found = []

for user_folder in os.listdir(root_folder):
    user_path = os.path.join(root_folder, user_folder)
    if not os.path.isdir(user_path):
        continue

    log_filename = f"WingetUpgradeLogFor-{user_folder}.txt"
    log_path = os.path.join(user_path, log_filename)

    try:
        with open(log_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                match = upgrade_line_pattern.match(line)
                if match:
                    name = match.group("Name").lower()
                    pkg_id = match.group("Id").lower()
                    if search_term in name or search_term in pkg_id:
                        found.append((user_folder, name, pkg_id, match.group("CurrentVersion"), match.group("AvailableVersion")))
                        break  # Only need to report each user once
    except FileNotFoundError:
        continue
    except Exception as e:
        continue

if found:
    print("Users with the specified upgrade available:")
    for user, name, pkg_id, cur, avail in found:
        print(f"{user}: {name} | {pkg_id} | {cur} -> {avail}")
else:
    print("No users found with that upgrade.")
