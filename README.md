<h1 align="center">tutum-startup</h1>

<p align="center">Register a new EC2 instance as a <a href="https://tutum.co">Tutum</a> node on launch.</p>

### What?

This script is run at startup on new EC2 instances ([`user-data`](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)) to register the instance as a [Tutum](https://tutum.co) node.

### Why?

At [Vidsy](http://vidsy.co) we wanted to use Tutum, but also benefit from the controls and features of AWS.

### Implementation

Currently the script:

- Installs `tutum-cli` and `aws-cli`.
- Sets environment variables for Tutum authentication.
- Uses "Bring Your Own Node" CLI command to register new instance as Tutum node.
- Remove nodes from Tutum which have become "`Unreachable`".
- Waits for Tutum deployment to finish.
- Retrieves EC2 instance tags.
- Adds each tag as a Tutum tag.
- Sends a Slack notification telling the team that a new instance was launched.
- Delete all installed packages and Bash history.

### To-Do

Look at any [open issues](https://github.com/vidsy/tutum-startup/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+label%3ATo-Do) labeled as `to-do`.

### Tutum Bugs

- Tutum does not allow tags to be added to a node until it has finished deploying.

### Notes

- Help improve this repo! 
- Feel free to ping me (`@revett`) with any questions, on the [Tutum community Slack](https://tutum-community.slack.com/).
- A lot of these ideas came from `@jskeates`, he helped a lot.
- [MIT License (MIT)](https://opensource.org/licenses/MIT).


