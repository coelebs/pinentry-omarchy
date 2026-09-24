import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root
  property var shell: null
  property string omarchyPath: ""
  property bool opened: false
  property string title: "Authentication"
  property string description: ""
  property string prompt: "Enter password"
  property string responseFile: ""
  property string responseProgram: ""
  property bool submitted: false
  property color accent: Color.polkit.accent
  property color background: Color.polkit.background
  property color foreground: Color.polkit.text
  property color border: Color.polkit.border
  property color scrim: Color.polkit.scrim
  readonly property int fieldHeight: Math.max(Style.space(42), Style.spacing.controlHeight)
  readonly property int contentMargin: Style.spacing.panelPadding
  readonly property int cardWidth: Math.min(Style.space(312), Math.max(Style.space(260), panel.width - Style.gapsOut * 2))
  readonly property var borderSpec: Border.surfaceSpec("polkit", "border", border, Math.max(1, Style.space(2)), "border-alpha")

  function open(payload) {
    var data
    try { data = JSON.parse(payload) } catch (error) { return }
    if (!data.replyFile || !data.replyProgram) return
    responseFile = String(data.replyFile)
    responseProgram = String(data.replyProgram)
    title = String(data.title || "Authentication")
    description = String(data.description || "")
    prompt = String(data.prompt || "Enter password")
    submitted = false
    passwordInput.text = ""
    opened = true
    Qt.callLater(function() { passwordInput.forceActiveFocus() })
  }

  // Cancel contract: a dismiss without submit still writes an EMPTY reply
  // file so the waiting caller returns "Operation cancelled" instead of
  // polling forever. Empty passwords are treated as cancel by the caller.
  function close() {
    if (opened && !submitted && responseFile !== "" && responseProgram !== "" && !responseWriter.running) {
      cancel()
    }
    opened = false
    passwordInput.text = ""
  }

  function cancel() {
    responseWriter.environment = ({ "PINENTRY_REPLY": "", "PINENTRY_RESPONSE_FILE": responseFile })
    responseWriter.command = [responseProgram]
    responseWriter.running = true
  }

  function submit() {
    submitted = true
    responseWriter.environment = ({ "PINENTRY_REPLY": passwordInput.text, "PINENTRY_RESPONSE_FILE": responseFile })
    responseWriter.command = [responseProgram]
    responseWriter.running = true
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "coelebs-pinentry"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle { anchors.fill: parent; color: root.scrim }
    MouseArea { anchors.fill: parent; onClicked: passwordInput.forceActiveFocus() }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.fieldHeight + root.contentMargin * 2
      anchors.centerIn: parent
      radius: Style.cornerRadius
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin
      MouseArea { anchors.fill: parent; onClicked: passwordInput.forceActiveFocus() }

      Row {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: Style.space(14)

        Text {
          text: "\uf023"
          color: root.accent
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.iconLarge
          width: Style.space(26)
          height: root.fieldHeight
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }

        Item {
          width: parent.width - Style.space(40)
          height: root.fieldHeight
          TextInput {
            id: passwordInput
            anchors.fill: parent
            verticalAlignment: TextInput.AlignVCenter
            activeFocusOnPress: true
            clip: true
            selectionColor: Util.alpha(root.accent, 0.45)
            selectedTextColor: root.foreground
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.iconLarge
            echoMode: TextInput.Password
            passwordCharacter: "*"
            color: root.foreground
            // onAccepted alone is unreliable on quickshell alphas: Enter
            // arrives as a plain key event, so handle Keys too.
            onAccepted: root.submit()
            Keys.onEnterPressed: root.submit()
            Keys.onReturnPressed: root.submit()
            Keys.onEscapePressed: root.close()
          }
          Text {
            anchors.fill: parent
            text: root.prompt
            color: root.foreground
            opacity: 0.36
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.iconLarge
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            visible: passwordInput.text.length === 0
          }
        }
      }
    }

    Rectangle {
      width: Math.min(label.implicitWidth + Style.space(24), panel.width - Style.gapsOut * 2)
      height: Style.space(28)
      anchors.horizontalCenter: card.horizontalCenter
      anchors.bottom: card.top
      anchors.bottomMargin: Style.space(10)
      radius: Style.cornerRadius
      color: root.background
      Text {
        id: label
        anchors.fill: parent
        anchors.leftMargin: Style.space(12)
        anchors.rightMargin: Style.space(12)
        text: root.description || root.title
        color: root.foreground
        font.family: Style.font.menuFamily
        font.pixelSize: Style.font.bodySmall
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideMiddle
      }
    }
  }

  Process {
    id: responseWriter
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) console.warn("[pinentry] reply program exited", exitCode, exitStatus)
      root.close()
    }
  }
}
