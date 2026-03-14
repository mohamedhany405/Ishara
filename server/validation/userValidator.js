// validation/userValidator.js

const Joi = require("joi");

const registerSchema = Joi.object({
    email: Joi.string()
        .trim()
        .lowercase()
        .email()
        .required()
        .messages({
            "string.email": "Please enter a valid email address.",
            "any.required": "Email is required.",
            "string.empty": "Email is required.",
        }),
    password: Joi.string()
        .min(8)
        .pattern(/^(?=.*[A-Za-z])(?=.*\d).+$/)
        .required()
        .messages({
            "string.min": "Password must be at least 8 characters.",
            "string.pattern.base": "Password must include at least 1 letter and 1 number.",
            "any.required": "Password is required.",
            "string.empty": "Password is required.",
        }),
    confirmPassword: Joi.string()
        .valid(Joi.ref("password"))
        .optional()
        .messages({
            "any.only": "Passwords do not match.",
        }),
    name: Joi.string()
        .trim()
        .min(3)
        .max(30)
        .required()
        .messages({
            "string.min": "Name must be at least 3 characters.",
            "string.max": "Name must be 30 characters or less.",
            "any.required": "Name is required.",
            "string.empty": "Name is required.",
        }),
    disabilityType: Joi.string()
        .valid("deaf", "non-verbal", "blind", "hearing")
        // Keep this field required in the data model, but default it so older clients
        // (or minimal forms) don't fail hard at registration.
        .default("hearing")
        .messages({
            "any.only": "Please choose a valid disability type.",
        }),
});

const loginSchema = Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required(),

});

const verifySchema = Joi.object({
    email: Joi.string().email().required(),
    otp: Joi.string().length(6).required(),
});

const resendOtpSchema = Joi.object({
    email: Joi.string().email().required(),
});

const forgotPasswordSchema = Joi.object({
    email: Joi.string().email().required(),
});

const resetPasswordSchema = Joi.object({
    token: Joi.string().required(),
    newPassword: Joi.string().min(8).required(),
});

module.exports = {
    registerSchema,
    verifySchema,
    loginSchema,
    resendOtpSchema,
    forgotPasswordSchema,
    resetPasswordSchema,
};
