require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./routes/authRoutes');
const requestRoutes = require('./routes/requestRoutes');
const diagnosisRoutes = require('./routes/diagnosisRoutes');
const zoneRoutes = require('./routes/zoneRoutes');
const mechanicRoutes = require('./routes/mechanicRoutes');
const customerRoutes = require('./routes/customerRoutes');
const { errorHandler } = require('./middleware/errorMiddleware');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGIN || false,
}));
app.use(express.json({ limit: '10kb' }));

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later' },
});

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/auth', authLimiter, authRoutes);
app.use('/requests', requestRoutes);
app.use('/diagnose', diagnosisRoutes);
app.use('/zones', zoneRoutes);
app.use('/mechanics', mechanicRoutes);
app.use('/customers', customerRoutes);

app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`Fundix backend running on port ${PORT}`);
});
