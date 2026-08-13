const mongoose = require('mongoose');

const collectionSchema = new mongoose.Schema({
  name: { type: String, required: true },
  workspace: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace' },
  parentFolder: { type: mongoose.Schema.Types.ObjectId, ref: 'Collection', default: null },
  sortOrder: { type: Number, default: 0 },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

module.exports = mongoose.model('Collection', collectionSchema);
