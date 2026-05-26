const express = require('express');
const router = express.Router();
const { requireAdmin } = require('../middleware/adminMiddleware');
const { listPending, listAll, approve, reject, updateLevel } = require('../controllers/adminController');

router.use(requireAdmin);

router.get('/mechanics/pending',         listPending);
router.get('/mechanics',                 listAll);
router.patch('/mechanics/:id/approve',   approve);
router.patch('/mechanics/:id/reject',    reject);
router.patch('/mechanics/:id/level',     updateLevel);

module.exports = router;
