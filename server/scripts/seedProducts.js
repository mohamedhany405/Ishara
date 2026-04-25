// Seed Ishara products. Run: node server/scripts/seedProducts.js
require("dotenv").config({ path: require("path").join(__dirname, "..", ".env") });
const mongoose = require("mongoose");
const Product = require("../models/Product");
const connectDB = require("../config/dbConfig");

const items = [
    {
        sku: "ISH-EARBUDS-01",
        title: { en: "Bluetooth Hearing Amplifier", ar: "سماعة مكبرة بلوتوث" },
        description: { en: "Pocket-size hearing amplifier with adjustable volume.", ar: "سماعة مكبرة محمولة بصوت قابل للضبط." },
        price: 1299,
        category: "hearing",
        tags: ["hearing", "amplifier", "bluetooth"],
        images: ["https://images.unsplash.com/photo-1606220588913-b3aacb4d2f37?w=600"],
        stock: 30,
    },
    {
        sku: "ISH-CANE-01",
        title: { en: "Smart White Cane", ar: "عصا بيضاء ذكية" },
        description: { en: "Ultrasonic obstacle-detection cane with vibration feedback.", ar: "عصا للمكفوفين بحساس فوق صوتي وتنبيه اهتزازي." },
        price: 1899,
        category: "blind",
        tags: ["blind", "cane", "obstacle"],
        images: ["https://images.unsplash.com/photo-1582738411706-bfc8e691d1c2?w=600"],
        stock: 15,
    },
    {
        sku: "ISH-BOOK-ARSL",
        title: { en: "Arabic Sign Language Picture Book", ar: "كتاب لغة الإشارة العربية المصور" },
        description: { en: "Learn 200+ Arabic signs with full-color illustrations.", ar: "تعلّم أكثر من 200 إشارة عربية مع صور توضيحية." },
        price: 249,
        category: "learning",
        tags: ["arsl", "book", "learning"],
        images: ["https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=600"],
        stock: 100,
    },
    {
        sku: "ISH-VIBE-WATCH",
        title: { en: "Vibration Alert Watch", ar: "ساعة تنبيه اهتزازية" },
        description: { en: "Silent vibrating watch for deaf users — alarms, timers, SOS.", ar: "ساعة اهتزازية صامتة للصم — منبهات ومؤقتات وSOS." },
        price: 799,
        category: "deaf",
        tags: ["deaf", "watch", "alert"],
        images: ["https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600"],
        stock: 50,
    },
    {
        sku: "ISH-MAGNIFY-01",
        title: { en: "Pocket Digital Magnifier", ar: "مكبر رقمي للجيب" },
        description: { en: "5x digital magnifier with high-contrast modes.", ar: "مكبر رقمي بقوة 5x وأوضاع تباين عالي." },
        price: 1450,
        category: "low-vision",
        tags: ["blind", "low-vision", "magnifier"],
        images: ["https://images.unsplash.com/photo-1503602642458-232111445657?w=600"],
        stock: 25,
    },
    {
        sku: "ISH-GLASSES-01",
        title: { en: "Ishara Smart Glasses", ar: "نظارات إشارة الذكية" },
        description: { en: "ESP32 glasses with obstacle detection, SOS button, microphone.", ar: "نظارات إشارة بحساس مسافة وزر SOS وميكروفون." },
        price: 3499,
        category: "hardware",
        tags: ["glasses", "hardware", "ishara"],
        images: ["https://images.unsplash.com/photo-1556306535-0f09a537f0a3?w=600"],
        stock: 10,
    },
    {
        sku: "ISH-FLASH-DOOR",
        title: { en: "Doorbell Flash Notifier", ar: "منبه ضوئي للباب" },
        description: { en: "Visual doorbell that flashes lights when someone is at the door.", ar: "جرس باب ضوئي ينبه بالومضات." },
        price: 599,
        category: "deaf",
        tags: ["deaf", "doorbell"],
        images: ["https://images.unsplash.com/photo-1558002038-1055907df827?w=600"],
        stock: 40,
    },
    {
        sku: "ISH-TTS-PEN",
        title: { en: "OCR Reading Pen", ar: "قلم قراءة OCR" },
        description: { en: "Scan-and-read pen with built-in TTS for printed text.", ar: "قلم يقرأ النصوص المطبوعة بصوت عالٍ." },
        price: 2199,
        category: "blind",
        tags: ["blind", "ocr", "tts"],
        images: ["https://images.unsplash.com/photo-1532465614-6cc8d45f647f?w=600"],
        stock: 20,
    },
];

(async () => {
    try {
        await connectDB();
        for (const item of items) {
            await Product.findOneAndUpdate({ sku: item.sku }, item, { upsert: true, new: true, setDefaultsOnInsert: true });
        }
        console.log(`Seeded ${items.length} products.`);
        await mongoose.disconnect();
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
})();
