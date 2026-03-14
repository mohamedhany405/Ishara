// sendEmail.js
require("dotenv").config();

const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

async function sendEmail(to, subject, text, html = null) {
    try {
        const mailOptions = {
            from: `"Ishara App" <${process.env.EMAIL_USER}>`,
            to,
            subject,
        };

        if (html) {
            mailOptions.html = html;
            mailOptions.text = text || html.replace(/<[^>]*>/g, "");
        } else {
            mailOptions.text = text;
        }

        const info = await transporter.sendMail(mailOptions);
        console.log("Email sent! Message ID:", info.messageId);
        return info;
    } catch (error) {
        console.error("Failed to send email:", error.message);
        throw error;
    }
}

module.exports = sendEmail;
