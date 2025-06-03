import os
import re

# 1. Set the root path to the network shared folder
root_folder = r"\\.......................\WingetUpgradeList-user"

# 2. Prepare a set to collect unique upgrades (by Id)
unique_upgrades = {}

# 3. Regex pattern to match upgrade lines (Name Id Version Available Source)
upgrade_line_pattern = re.compile(
    r"^(?P<Name>.+?)\s+(?P<Id>[^\s]+)\s+(?P<CurrentVersion>[^\s]+)\s+(?P<AvailableVersion>[^\s]+)\s+(?P<Source>[^\s]+)$"
)

# 4. Loop through each user's subfolder
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
                # Skip header lines or lines with pipes (|) or timestamps
                lower_line = line.lower()
                if (
                    lower_line.startswith("name |")
                    or lower_line.startswith("name id version available source")
                    or lower_line.startswith("name | id | version | available | source")
                    or re.match(r"\d{4}-\d{2}-\d{2}", line)
                    or (
                        "name" in lower_line and
                        "id" in lower_line and
                        "version" in lower_line and
                        "available" in lower_line and
                        "source" in lower_line
                    )
                    or "the `msstore` source requires that you view the" in lower_line
                    or "the source requires the current machine's 2-letter geographic region" in lower_line
                ):
                    continue
                match = upgrade_line_pattern.match(line)
                if match:
                    # Use Id as the unique key
                    upgrade_id = match.group("Id")
                    # Store the tuple (Name, Id, CurrentVersion, AvailableVersion, Source)
                    unique_upgrades[upgrade_id] = (
                        match.group("Name"),
                        upgrade_id,
                        match.group("CurrentVersion"),
                        match.group("AvailableVersion"),
                        match.group("Source"),
                    )
    except FileNotFoundError:
        continue
    except Exception as e:
        continue

# 5. Output combined unique upgrades to a new file
output_file = os.path.join(root_folder, "All_Unique_Winget_Upgrades.txt")
with open(output_file, "w", encoding="utf-8") as out:
    # 6. Write column headers
    out.write("Name | ID | Current Version | Available Version | Source\n")
    out.write("-" * 70 + "\n")
    # Write each unique upgrade entry
    for entry in sorted(unique_upgrades.values(), key=lambda x: x[0].lower()):
        out.write(f"{entry[0]} | {entry[1]} | {entry[2]} | {entry[3]} | {entry[4]}\n")
