# Filter last five versions
def filter_last_five_versions:
  .[0:5];

# Add tags to the first object
def add_latest_tag_to_first_object(gitref):
  .[0] |= . + { "tags": [if gitref == "main" then "latest" else "edge" end] };

# Add version as tags to all objects, if it is first object then add latest
def add_version_to_tags(gitref):
  .[] |= . + { "tags": (.tags + [(if gitref != "main" then "edge-" else "" end) + .version]) };

# Add latest commit as tags to all objects
def add_commit_to_tags(gitref):
  .[] |= . + { "tags": (.tags + [(if gitref != "main" then "edge-" else "" end) + (.commits | first)]) };

def add_latest_commit_as_ref:
  .[] |= . + { "ref": (.commits | first) };

# Apply both filters
add_latest_commit_as_ref | filter_last_five_versions | add_latest_tag_to_first_object($gitref) | add_version_to_tags($gitref) | add_commit_to_tags($gitref)
