const { body, validationResult } = require('express-validator');

const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ 
      error: 'Validation failed',
      details: errors.array()
    });
  }
  next();
};

const registerValidation = [
  body('username')
    .isLength({ min: 3, max: 30 })
    .withMessage('Username must be between 3 and 30 characters')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username can only contain letters, numbers, and underscores')
    .trim()
    .escape(),
  body('email')
    .isEmail()
    .withMessage('Please provide a valid email')
    .normalizeEmail()
    .trim(),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  body('firstName')
    .notEmpty()
    .withMessage('First name is required')
    .isLength({ max: 50 })
    .withMessage('First name must be less than 50 characters')
    .trim()
    .escape(),
  body('lastName')
    .notEmpty()
    .withMessage('Last name is required')
    .isLength({ max: 50 })
    .withMessage('Last name must be less than 50 characters')
    .trim()
    .escape(),
];

const loginValidation = [
  body('email')
    .isEmail()
    .withMessage('Please provide a valid email')
    .normalizeEmail()
    .trim(),
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
];

const skillValidation = [
  body('title')
    .isLength({ min: 5, max: 100 })
    .withMessage('Title must be between 5 and 100 characters')
    .trim()
    .escape(),
  body('description')
    .isLength({ min: 10 })
    .withMessage('Description must be at least 10 characters long')
    .trim()
    .escape(),
  body('category')
    .notEmpty()
    .withMessage('Category is required')
    .trim()
    .escape(),
  body('type')
    .isIn(['offer', 'request'])
    .withMessage('Type must be either "offer" or "request"'),
  body('level')
    .optional()
    .isIn(['beginner', 'intermediate', 'advanced'])
    .withMessage('Level must be beginner, intermediate, or advanced'),
  body('location')
    .optional()
    .isIn(['online', 'in-person', 'both'])
    .withMessage('Location must be online, in-person, or both'),
];

const matchValidation = [
  body('offerSkillId')
    .notEmpty()
    .withMessage('Offer skill ID is required')
    .isUUID()
    .withMessage('Offer skill ID must be a valid UUID'),
  body('requestSkillId')
    .notEmpty()
    .withMessage('Request skill ID is required')
    .isUUID()
    .withMessage('Request skill ID must be a valid UUID'),
  body('message')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Message must be less than 500 characters'),
];

module.exports = {
  handleValidationErrors,
  registerValidation,
  loginValidation,
  skillValidation,
  matchValidation,
};
