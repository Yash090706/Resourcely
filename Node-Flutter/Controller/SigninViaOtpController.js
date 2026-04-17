const nodemailer = require("nodemailer");
const { otp_model } = require("../Models/OtpModels");

const send_otp = async (req, res, next) => {
  const { email } = req.body;

  if (!email) {
    return next({ statuscode: 404, message: "Email Not Found" });
  }

  const otp = Math.floor(100000 + Math.random() * 900000);

  try {
    let transporter = await nodemailer.createTransport({
      service: "gmail",
      port: 587,
      secure: false,
      auth: {
        user: process.env.EMAIL_URL,
        pass: process.env.APP_PASSWORD,
      },
    });

    const message = await transporter.sendMail({
      from: `"Resourcely" <${process.env.EMAIL_URL}>`,
      to: email,
      subject: "Your Resourcely OTP is Here",
      text: "Your Resourcely OTP is Here",
      html: `<h2>Your OTP is ${otp}</h2>`,
    });

    const otp_save = new otp_model({
      email: email,
      otp: otp,
    });

    await otp_save.save();

    res.status(200).json({
      status: 1,
      success: true,
      msg: "OTP Sent to Mail",
      previewURL: nodemailer.getTestMessageUrl(message),
    });
  } catch (err) {
    return next(err);
  }
};

const verify_otp = async (req, res, next) => {
  const { otp, email } = req.body;

  if (!otp || !email) {
    return next({
      statuscode: 400,
      message: "OTP or Email missing",
    });
  }

  try {
    const fetch_otp = await otp_model.findOne({
      otp: otp,
      email: email,
    });

    if (!fetch_otp) {
      return res.status(400).json({
        success: false,
        message: "Invalid OTP",
      });
    }

    // delete otp after verification
    await otp_model.deleteOne({
      _id: fetch_otp._id,
    });

    return res.status(200).json({
      success: true,
      message: "OTP Verified Successfully",
      email: email,
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { send_otp, verify_otp };