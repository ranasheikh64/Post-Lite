const Collection = require('../models/Collection');
const Request = require('../models/Request');

exports.createCollection = async (req, res) => {
  try {
    const collection = await Collection.create({ ...req.body, createdBy: req.user.id });
    res.status(201).json(collection);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

exports.getCollections = async (req, res) => {
  try {
    // Fetch all collections for the user
    const collections = await Collection.find({ createdBy: req.user.id }).lean();
    
    // Fetch all requests belonging to these collections
    const requests = await Request.find({ 
      collectionId: { $in: collections.map(c => c._id) } 
    }).lean();

    // Group requests by collection and sort them
    const requestsByCollection = {};
    requests.forEach(r => {
      if (!requestsByCollection[r.collectionId]) {
        requestsByCollection[r.collectionId] = [];
      }
      requestsByCollection[r.collectionId].push(r);
    });

    // Attach sorted requests to collections
    const collectionsWithRequests = collections.map(c => {
      const collectionRequests = requestsByCollection[c._id] || [];
      collectionRequests.sort((a, b) => (a.sortOrder || 0) - (b.sortOrder || 0));
      return {
        ...c,
        requests: collectionRequests,
        folders: [] // Initialize folders array
      };
    });

    // Build hierarchy
    const rootCollections = [];
    const collectionMap = {};

    collectionsWithRequests.forEach(c => {
      collectionMap[c._id.toString()] = c;
    });

    collectionsWithRequests.forEach(c => {
      if (c.parentFolder) {
        const parent = collectionMap[c.parentFolder.toString()];
        if (parent) {
          parent.folders.push(c);
          parent.folders.sort((a, b) => (a.sortOrder || 0) - (b.sortOrder || 0));
        } else {
          rootCollections.push(c);
        }
      } else {
        rootCollections.push(c);
      }
    });

    res.json(rootCollections);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateCollection = async (req, res) => {
  try {
    const updated = await Collection.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(updated);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

exports.deleteCollection = async (req, res) => {
  try {
    const id = req.params.id;

    // Helper function to get all child collection IDs recursively
    const getAllChildCollectionIds = async (parentId) => {
      let ids = [];
      const children = await Collection.find({ parentFolder: parentId }).lean();
      for (const child of children) {
        ids.push(child._id);
        const nestedIds = await getAllChildCollectionIds(child._id);
        ids = ids.concat(nestedIds);
      }
      return ids;
    };

    const allCollectionIds = [id, ...(await getAllChildCollectionIds(id))];

    // Delete all requests belonging to these collections
    await Request.deleteMany({ collectionId: { $in: allCollectionIds } });

    // Delete all collections
    await Collection.deleteMany({ _id: { $in: allCollectionIds } });

    res.status(204).send();
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.importCollection = async (req, res) => {
  try {
    const postmanCollection = req.body;
    if (!postmanCollection || !postmanCollection.info) {
      return res.status(400).json({ message: 'Invalid Postman Collection JSON' });
    }

    const rootCollectionName = postmanCollection.info.name || 'Imported Collection';
    
    const rootCollection = await Collection.create({
      name: rootCollectionName,
      createdBy: req.user.id
    });

    let requestCount = 0;
    let folderCount = 0;

    const parseItems = async (items, parentId) => {
      if (!items || !Array.isArray(items)) return;

      for (let i = 0; i < items.length; i++) {
        const item = items[i];
        
        if (item.item && Array.isArray(item.item)) {
          const folder = await Collection.create({
            name: item.name || 'Folder',
            parentFolder: parentId,
            createdBy: req.user.id,
            sortOrder: i
          });
          folderCount++;
          await parseItems(item.item, folder._id);
        } else if (item.request) {
          let method = 'GET';
          let url = '';
          let docs = '';
          let headers = [];
          let queryParams = [];
          let authType = 'inherit';
          let authConfig = {};
          let bodyType = 'none';
          let bodyFormat = 'json';
          let body = {};

          if (item.request.method) method = item.request.method.toUpperCase();
          if (item.request.description) docs = item.request.description;

          if (typeof item.request.url === 'string') {
            url = item.request.url;
          } else if (item.request.url) {
            if (typeof item.request.url.raw === 'string') {
              url = item.request.url.raw;
            }
            if (Array.isArray(item.request.url.query)) {
              queryParams = item.request.url.query.map(q => ({
                key: q.key || '',
                value: q.value || '',
                description: q.description || '',
                enabled: q.disabled !== true
              }));
            }
          }

          if (Array.isArray(item.request.header)) {
            headers = item.request.header.map(h => ({
              key: h.key || '',
              value: h.value || '',
              description: h.description || '',
              enabled: h.disabled !== true
            }));
          }

          if (item.request.auth) {
            authType = item.request.auth.type || 'inherit';
            if (item.request.auth[authType]) {
              // Postman stores auth config as an array of {key, value, type} objects
              if (Array.isArray(item.request.auth[authType])) {
                item.request.auth[authType].forEach(field => {
                  authConfig[field.key] = field.value;
                });
              } else {
                authConfig = item.request.auth[authType];
              }
            }
          }

          if (item.request.body) {
            if (item.request.body.mode === 'raw') {
              bodyType = 'raw';
              body = item.request.body.raw || '';
              if (item.request.body.options && item.request.body.options.raw && item.request.body.options.raw.language) {
                bodyFormat = item.request.body.options.raw.language;
              }
            } else if (item.request.body.mode === 'formdata') {
              bodyType = 'form-data';
              if (Array.isArray(item.request.body.formdata)) {
                body = item.request.body.formdata.map(fd => ({
                  key: fd.key || '',
                  value: fd.value || '',
                  type: fd.type || 'text',
                  enabled: fd.disabled !== true
                }));
              }
            } else if (item.request.body.mode === 'urlencoded') {
              bodyType = 'urlencoded';
              if (Array.isArray(item.request.body.urlencoded)) {
                body = item.request.body.urlencoded.map(ue => ({
                  key: ue.key || '',
                  value: ue.value || '',
                  enabled: ue.disabled !== true
                }));
              }
            } else if (item.request.body.mode === 'graphql') {
              bodyType = 'graphql';
              body = item.request.body.graphql || {};
            } else if (item.request.body.mode === 'file') {
              bodyType = 'file';
              body = item.request.body.file || {};
            }
          }

          await Request.create({
            name: item.name || 'Request',
            collectionId: parentId,
            sortOrder: i,
            method: method,
            url: url,
            docs: docs,
            headers: headers,
            queryParams: queryParams,
            authType: authType,
            authConfig: authConfig,
            bodyType: bodyType,
            bodyFormat: bodyFormat,
            body: body,
            createdBy: req.user.id
          });
          requestCount++;
        }
      }
    };

    await parseItems(postmanCollection.item, rootCollection._id);

    res.status(201).json({
      message: 'Collection imported successfully',
      rootCollectionId: rootCollection._id,
      stats: { folders: folderCount, requests: requestCount }
    });
  } catch (err) {
    console.error('Import error:', err);
    res.status(500).json({ message: 'Failed to import collection: ' + err.message });
  }
};
