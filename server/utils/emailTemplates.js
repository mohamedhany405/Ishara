function otpEmail({ name, otp }) {
  const safeName = (name || "there").trim() || "there";

  return {
    subject: "Your Ishara verification code",
    text: `Hello ${safeName},\n\nYour OTP code is: ${otp}\nThis code expires in 10 minutes.\n\nIf you did not request this, please ignore this email.`,
    html: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #111827;">
        <h2 style="margin-bottom: 8px;">Verify your Ishara account</h2>
        <p>Hello ${safeName},</p>
        <p>Your OTP code is:</p>
        <p style="font-size: 24px; font-weight: 700; letter-spacing: 4px; margin: 12px 0;">${otp}</p>
        <p>This code expires in <strong>10 minutes</strong>.</p>
        <p>If you did not request this, you can safely ignore this email.</p>
      </div>
    `.trim(),
  };
}

function resetPasswordEmail({ name, resetUrl }) {
  const safeName = (name || "there").trim() || "there";

  return {
    subject: "Reset your Ishara password",
    text: `Hello ${safeName},\n\nYou requested to reset your password.\nUse this link: ${resetUrl}\n\nThis link expires in 1 hour.\nIf you did not request a reset, please ignore this email.`,
    html: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #111827;">
        <h2 style="margin-bottom: 8px;">Reset your Ishara password</h2>
        <p>Hello ${safeName},</p>
        <p>You requested to reset your password.</p>
        <p>
          <a href="${resetUrl}" style="display: inline-block; padding: 10px 16px; background: #0ea5a4; color: #ffffff; text-decoration: none; border-radius: 6px;">
            Reset Password
          </a>
        </p>
        <p>If the button does not work, use this URL:</p>
        <p><a href="${resetUrl}">${resetUrl}</a></p>
        <p>This link expires in <strong>1 hour</strong>.</p>
      </div>
    `.trim(),
  };
}

module.exports = {
  otpEmail,
  resetPasswordEmail,
};
