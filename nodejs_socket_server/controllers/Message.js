const {Messages, User} = require("../models/index");
const {Human} = require("../models");

async function getAllMessages(roomInfo) {
    const payload = await Messages.find({
        room: roomInfo,
    });
    return payload;
}

async function addMessage(message, roomInfo) {
    const payload = await Messages.create(
        {
            msg: message.msg,
            id: message.id,
            room: roomInfo,
        }
    );
    return payload;
}

async function getAllUsers() {
    const payload = await User.find({})
    return payload;
}

async function createHuman() {
    const payload = await Human.create(
        {
            id: 3,
            name: "Victoria Kim",
            image:
                "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?ixid=MXwxMjA3fDB8MHxzZWFyY2h8M3x8bW9kZWx8ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60",
        }
    );
    return payload;
}

module.exports = {
    createHuman,
    getAllUsers,
    getAllMessages,
    addMessage,
};
