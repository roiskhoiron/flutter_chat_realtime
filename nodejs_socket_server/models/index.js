const mongoose = require('mongoose');
const MessageSchema = require('./Messages')
const UserSchema = require('./User')
const HumanSchema = require('./human')

const Schema = mongoose.Schema

const createSchema = (schema) => {
  const model = new Schema(schema, { timestamps: true })
  return model
}

const Messages = mongoose.model('Messages', createSchema(MessageSchema))

const User = mongoose.model('user', createSchema(UserSchema))

const Human = mongoose.model('human', createSchema(HumanSchema));


module.exports = {
  Messages,
  User,
  Human
}