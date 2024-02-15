# Filter last five versions
def filter_last_five_versions:
  .[0:5];

# Add tags to the first object
def add_latest_tag_to_first_object(gitref):
  .[0] |= . + { "tags": (.tags + [if gitref == "main" then "latest" else "edge" end]) };

# Add version as tags to all objects, if it is first object then add latest
def add_version_to_tags(gitref):
  .[] |= . + { "tags": (.tags + [.version + (if gitref != "main" then "-edge" else "" end)]) };

# Add latest commit as tags to all objects
def add_commit_to_tags(gitref):
  .[] |= . + { "tags": (.tags + [(.commits | first)[:7] + (if gitref != "main" then "-edge" else "" end), (.commits | first) + (if gitref != "main" then "-edge" else "" end)]) };

def add_latest_commit_as_ref:
  .[] |= . + { "ref": (.commits | first) };

# Apply both filters
add_latest_commit_as_ref | filter_last_five_versions | add_version_to_tags($gitref) | add_commit_to_tags($gitref) | add_latest_tag_to_first_object($gitref)
