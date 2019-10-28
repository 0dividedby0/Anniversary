//MARK: - Notifications
const apn = require('apn');

let options = {
  token: {
    key: "AuthKey_8Z5VT36KSJ.p8",
    keyId: "8Z5VT36KSJ",
    teamId: "V3KUY8J833"
  },
  production: true
};

let apnProvider = new apn.Provider(options);
var deviceTokens = [];

//MARK: - ServerIO
const express = require('express');
const app = express();
const io = require('socket.io');
const fs = require('fs')

var messages = [];
var plans = [];
var memories = [];

messages = fs.readFileSync('Logs/messages.txt').toString('utf8').match(/[^,]+,[^,]+,[^,]+/g);
if (messages != null) {
    messages.forEach(function(part, index) {
        this[index] = this[index].split(',');
    }, messages);
}
else {
    messages = [];
}

var rawPlans = fs.readFileSync('Logs/plans.txt').toString('utf8').split('\n');
var state = "name";
if (rawPlans != null) {
    for (var i = 0; i < rawPlans.length-1; i++) {
        var rawPlansSplit = rawPlans[i].split(';');
        var activities = [], flights = [], maps = [], budget = [], notes = [];
        var A = rawPlansSplit.indexOf('A');
        var F = rawPlansSplit.indexOf('F');
        var M = rawPlansSplit.indexOf('M');
        var B = rawPlansSplit.indexOf('B');
        var N = rawPlansSplit.indexOf('N');
        for (var j = A+1; j < F; j++) {
            activities.push(rawPlansSplit[j]);
        }
        for (var j = F+1; j < M; j++) {
            flights.push(rawPlansSplit[j]);
        }
        for (var j = M+1; j < B; j++) {
            maps.push(rawPlansSplit[j]);
        }
        for (var j = B+1; j < N; j++) {
            budget.push(rawPlansSplit[j]);
        }
        for (var j = N+1; j < rawPlansSplit.length; j++) {
            notes.push(rawPlansSplit[j]);
        }
        plans[rawPlansSplit[0]] = [[rawPlansSplit[1]],[rawPlansSplit[2]],[rawPlansSplit[3]],activities,flights,maps,budget,notes,[rawPlansSplit[0]]];
    }
    //console.log(plans);
}
if (plans == null) plans = [];

var rawMemories = fs.readFileSync('Logs/memories.txt').toString('utf8').split('\n');
if (rawMemories != null) {
    for (var i = 0; i < rawMemories.length-1; i++) {
        var rawMemoriesSplit = rawMemories[i].split(';');
        memories[rawMemoriesSplit[0]] = [rawMemoriesSplit[1],rawMemoriesSplit[2],rawMemoriesSplit[3],rawMemoriesSplit[0],rawMemoriesSplit[4]]
    }
}
if (memories == null) memories = [];
//console.log(memories);

app.use(express.json());

const server = app.listen(3000, () => console.log('Server listening on 73.140.192.13:3000'));

app.get('/', (req, res) => res.send("Hello World!"));

var serverio = io.listen(server);

serverio.on('connection', function(socket) {
    console.log('User Connected!');

    socket.on('deviceTokenRegistered', function (username, token) {
        deviceTokens[token] = username;
        // Record the new token
        var fileOutput = ""
        Object.keys(deviceTokens).forEach(function(key) {
            fileOutput = fileOutput + key+':'+deviceTokens[key]+'\n'
        });
        fs.writeFile('Logs/tokens.txt', fileOutput, function (err) {
            if (err) throw err;
            console.log('Saved!');
        });
        console.log(deviceTokens);
    })

    //MARK: - MESSAGES
    socket.on('newMessageFromClient', function (sender, message, date) {
        messages.push([sender,message,date]);
        serverio.emit('newMessageFromServer', sender, message);

        // Prepare the notification
        let notification = new apn.Notification();
        notification.expiry = Math.floor(Date.now() / 1000) + 24 * 3600; // will expire in 24 hours from now
        notification.badge = 2;
        notification.sound = "ping.aiff";
        notification.alert = sender + ": " + message;
        notification.topic = "jhalcomb.Anniversary";

        // Send the notification
        Object.keys(deviceTokens).forEach(function(key) {
            if (deviceTokens[key] != sender){
                apnProvider.send(notification, key).then( result => {
                    console.log(result);
                });
            }
        });

        // Record the new message
        fs.writeFile('Logs/messages.txt', messages, function (err) {
            if (err) throw err;
            console.log('Saved!');
        });
    });

    socket.on('allMessagesRequest', function () {
        //console.log(messages)
        serverio.emit('allMessagesFromServer', messages);
    });

    //MARK: - HOME
    socket.on('clientNeedsAttention', function (sender) {
        // Prepare the notification
        let notification = new apn.Notification();
        notification.expiry = Math.floor(Date.now() / 1000) + 24 * 3600; // will expire in 24 hours from now
        notification.badge = 2;
        notification.sound = "ping.aiff";
        notification.alert = sender + " wants attention!!!";
        notification.topic = "jhalcomb.Anniversary";

        // Send the notification
        Object.keys(deviceTokens).forEach(function(key) {
            if (deviceTokens[key] != sender){
                apnProvider.send(notification, key).then( result => {
                    console.log(result);
                });
            }
        });
    });

    //MARK: - PLANS
    socket.on('newPlanFromClient', function(sender, name, location, date, activities, flights, map, budget, notes, id) {
        plans[id] = [[name],[location],[date],activities,flights,map,budget,notes,[id]];
        //console.log(plans)
        serverio.emit('newPlanFromServer',name,location,date,activities,flights,map,budget,notes,id);

        // Prepare the notification
        let notification = new apn.Notification();
        notification.expiry = Math.floor(Date.now() / 1000) + 24 * 3600; // will expire in 24 hours from now
        notification.badge = 2;
        notification.sound = "ping.aiff";
        notification.alert = "New Plan: " + name + "!";
        notification.topic = "jhalcomb.Anniversary";

        // Send the notification
        Object.keys(deviceTokens).forEach(function(key) {
            if (deviceTokens[key] != sender){
                apnProvider.send(notification, key).then( result => {
                    console.log(result);
                });
            }
        });

        // Record the new plan
        var fileOutput = ""
        Object.keys(plans).forEach(function(key) {
            fileOutput = fileOutput + plans[key][8]+';'+plans[key][0]+';'+plans[key][1]+';'+plans[key][2]+';A;'+plans[key][3]+';F;'+plans[key][4]+';M;'+plans[key][5]+';B;'+plans[key][6]+';N;'+plans[key][7]+'\n'
        });

        fs.writeFile('Logs/plans.txt', fileOutput, function (err) {
            if (err) throw err;
            console.log('Saved!');
        });
    });

    socket.on('allPlansRequest', function () {
        let planArray = [];
        Object.keys(plans).forEach(function(key) {
            planArray.push(plans[key]);
        });
        serverio.emit('allPlansFromServer', planArray);
    });

    socket.on('deletePlanAt', function(id) {
        delete plans[id]

        var fileOutput = ""
        Object.keys(plans).forEach(function(key) {
            fileOutput = fileOutput + plans[key][8]+';'+plans[key][0]+';'+plans[key][1]+';'+plans[key][2]+';A;'+plans[key][3]+';F;'+plans[key][4]+';M;'+plans[key][5]+';B;'+plans[key][6]+';N;'+plans[key][7]+'\n'
        });

        fs.writeFile('Logs/plans.txt', fileOutput, function (err) {
            if (err) throw err;
            console.log('Saved!');
        });
    });


    //MARK: - MEMORIES
    socket.on('newMemoryFromClient', function(sender, title, date, description, id, image) {
        memories[id] = [title, date, description, id, image];
        //console.log(memories)
        serverio.emit('newMemoryFromServer',title,date,description,id,image);

        // Prepare the notification
        let notification = new apn.Notification();
        notification.expiry = Math.floor(Date.now() / 1000) + 24 * 3600; // will expire in 24 hours from now
        notification.badge = 2;
        notification.sound = "ping.aiff";
        notification.alert = "New Memory: " + title + "!";
        notification.topic = "jhalcomb.Anniversary";

        // Send the notification
        Object.keys(deviceTokens).forEach(function(key) {
            if (deviceTokens[key] != sender){
                apnProvider.send(notification, key).then( result => {
                    console.log(result);
                });
            }
        });

        // Record the new memory
        var fileOutput = ""
        Object.keys(memories).forEach(function(key) {
            fileOutput = fileOutput + memories[key][3]+';'+memories[key][0]+';'+memories[key][1]+';'+memories[key][2]+memories[key][4]+'\n'
        });

        fs.writeFile('Logs/memories.txt', fileOutput, function (err) {
            if (err) throw err;
            console.log('Saved!');
        });
    });

    socket.on('allMemoriesRequest', function () {
        let memoryArray = [];
        Object.keys(memories).forEach(function(key) {
            memoryArray.push(memories[key]);
        });
        serverio.emit('allMemoriesFromServer', memoryArray);
    });

    socket.on('deleteMemoryAt', function(id) {
        delete memories[id]
        var fileOutput = ""
        Object.keys(memories).forEach(function(key) {
            fileOutput = fileOutput + memories[key][3]+';'+memories[key][0]+';'+memories[key][1]+';'+memories[key][2]+memories[key][4]+'\n'
        });

        fs.writeFile('Logs/memories.txt', fileOutput, function (err) {
            if (err) throw err;
            console.log('Saved!');
        });
    });

});
