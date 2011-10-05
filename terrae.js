var term = null;
var shell = null;
var id = -1;
var parser = null;
var timerid = null;

// Callback for messages from the terminal.
function readCallback(result)
{
	var payload = eval('(' + result.type + ')');
	
	if ("idle" in payload) {
		// Wait
		timerid = setTimeout("timerid = null; readData()", 200);
	} else if (payload.data) {
		parser.acceptData(payload.data);
		
		// Read more!
		readData();
	} else {
		console.info("No data!?");
	}
}

function readData(result) {
	if (timerid) {
	    clearTimeout(timerid);
	    timerid = null;
	}
	
	lunaService("luna://com.palm.terrae/read", "{\"id\": " + id + "}", readCallback);
}

function shellCallback(result)
{
	var payload = eval('(' + result.type + ')');
	
	if (payload.shell) {
	    shell = payload.shell;
	    open();
	} else {
	    console.info("Error getting shell.");
	}
}

function openDone(result)
{
    var payload = eval('(' + result.type + ')');
	
    if ("id" in payload) {
		id = payload.id;
		readData();
    } else {
		console.info("Error: No ID received: " + result.type);
    }
}

function open()
{
	if (shell == null) {
		lunaService("luna://com.palm.terrae/getShell", "{}", shellCallback);
		
		return;
	}
	
	lunaService("luna://com.palm.terrae/open", "{}", openDone);
}

function keyhandler(e) {
	lunaService("luna://com.palm.terrae/write", "{\"id\": " + id + ", \"data\": \"" + String.fromCharCode(e.which) + "\" }");
}

function terminalInit() {
    parser = new VT100Parser();
	
    open();

    document.captureEvents(Event.KEYPRESS);
    document.onkeypress = keyhandler;
}
