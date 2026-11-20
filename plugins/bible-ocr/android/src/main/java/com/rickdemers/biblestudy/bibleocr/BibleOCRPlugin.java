package com.rickdemers.biblestudy.bibleocr;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Rect;
import android.util.Base64;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.text.Text;
import com.google.mlkit.vision.text.TextRecognition;
import com.google.mlkit.vision.text.TextRecognizer;
import com.google.mlkit.vision.text.latin.TextRecognizerOptions;

import org.json.JSONException;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * On-device OCR for the Bible Study app ("Link Bible to our app" / snap a page),
 * using ML Kit Text Recognition v2 (Latin script, on-device model).
 *
 * JS contract — the native bridge injects {@code window.Capacitor.Plugins.BibleOCR}
 * automatically, so the web side calls
 * {@code window.Capacitor.Plugins.BibleOCR.recognizeText({ image })} directly:
 *   input:  { image: string } — base64 JPEG, no {@code data:} prefix
 *   output: { lines: [{ text, x, y, width, height }] } — boxes normalized
 *           0–1, origin TOP-LEFT (ML Kit / Android bitmaps are already top-left)
 *   errors: code "INVALID_IMAGE" when the base64 cannot be decoded as an image;
 *           code "RECOGNITION_FAILED" if ML Kit itself errors.
 *           No text found resolves with an empty {@code lines} array.
 *
 * Nothing leaves the device: the photo is decoded and read in memory only.
 */
@CapacitorPlugin(name = "BibleOCR")
public class BibleOCRPlugin extends Plugin {

    private TextRecognizer recognizer;

    @Override
    public void load() {
        recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS);
    }

    @PluginMethod
    public void recognizeText(PluginCall call) {
        String base64 = call.getString("image");
        if (base64 == null || base64.isEmpty()) {
            call.reject("Could not decode image", "INVALID_IMAGE");
            return;
        }
        byte[] bytes;
        try {
            bytes = Base64.decode(base64, Base64.DEFAULT);
        } catch (IllegalArgumentException e) {
            call.reject("Could not decode image", "INVALID_IMAGE");
            return;
        }
        Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
        if (bitmap == null) {
            call.reject("Could not decode image", "INVALID_IMAGE");
            return;
        }

        InputImage image = InputImage.fromBitmap(bitmap, 0);
        recognizer.process(image)
                .addOnSuccessListener(text -> {
                    try {
                        JSArray lines = new JSArray();
                        for (Line line : orderLines(extractLines(text, bitmap))) {
                            JSObject o = new JSObject();
                            o.put("text", line.text);
                            o.put("x", line.x);
                            o.put("y", line.y);
                            o.put("width", line.width);
                            o.put("height", line.height);
                            lines.put(o);
                        }
                        JSObject result = new JSObject();
                        result.put("lines", lines);
                        call.resolve(result);
                    } catch (JSONException e) {
                        call.reject("Text recognition failed: " + e.getMessage(), "RECOGNITION_FAILED");
                    }
                })
                .addOnFailureListener(e ->
                        call.reject("Text recognition failed: " + e.getMessage(), "RECOGNITION_FAILED"));
    }

    /** One recognized line, box normalized 0–1 with origin TOP-LEFT. */
    private static class Line {
        final String text;
        final double x, y, width, height;

        Line(String text, double x, double y, double width, double height) {
            this.text = text;
            this.x = x;
            this.y = y;
            this.width = width;
            this.height = height;
        }

        double xCenter() {
            return x + width / 2.0;
        }
    }

    private static List<Line> extractLines(Text text, Bitmap bitmap) {
        List<Line> lines = new ArrayList<>();
        int w = bitmap.getWidth();
        int h = bitmap.getHeight();
        for (Text.TextBlock block : text.getTextBlocks()) {
            for (Text.Line line : block.getLines()) {
                Rect box = line.getBoundingBox();
                if (box == null) {
                    continue;
                }
                String s = line.getText();
                if (s == null || s.trim().isEmpty()) {
                    continue;
                }
                lines.add(new Line(s,
                        (double) box.left / w,
                        (double) box.top / h,
                        (double) box.width() / w,
                        (double) box.height() / h));
            }
        }
        return lines;
    }

    /**
     * Reading order, two-column aware — same algorithm as the iOS plugin
     * (see BibleOCR.swift): sort by x-center, find the largest gap; if it is
     * wider than 12% of the page width with at least 3 lines on each side and
     * the left group's median x-center &lt; 0.5 while the right group's is
     * &gt; 0.5, emit the left column top-to-bottom then the right column;
     * otherwise emit the whole page top-to-bottom. Within a column, sort by
     * y (top first), then x (left first).
     */
    private static List<Line> orderLines(List<Line> lines) {
        if (lines.size() <= 1) {
            return lines;
        }
        List<Line> byXCenter = new ArrayList<>(lines);
        Collections.sort(byXCenter, (a, b) -> Double.compare(a.xCenter(), b.xCenter()));

        double largestGap = 0;
        int splitIndex = 0;
        for (int i = 1; i < byXCenter.size(); i++) {
            double gap = byXCenter.get(i).xCenter() - byXCenter.get(i - 1).xCenter();
            if (gap > largestGap) {
                largestGap = gap;
                splitIndex = i;
            }
        }

        List<Line> left = new ArrayList<>(byXCenter.subList(0, splitIndex));
        List<Line> right = new ArrayList<>(byXCenter.subList(splitIndex, byXCenter.size()));
        if (largestGap > 0.12 && left.size() >= 3 && right.size() >= 3
                && medianXCenter(left) < 0.5 && medianXCenter(right) > 0.5) {
            List<Line> ordered = new ArrayList<>(sortColumn(left));
            ordered.addAll(sortColumn(right));
            return ordered;
        }
        return sortColumn(lines);
    }

    private static List<Line> sortColumn(List<Line> lines) {
        List<Line> sorted = new ArrayList<>(lines);
        Collections.sort(sorted, (a, b) -> {
            if (a.y != b.y) {
                return Double.compare(a.y, b.y);
            }
            return Double.compare(a.x, b.x);
        });
        return sorted;
    }

    private static double medianXCenter(List<Line> lines) {
        List<Double> centers = new ArrayList<>();
        for (Line line : lines) {
            centers.add(line.xCenter());
        }
        Collections.sort(centers);
        int n = centers.size();
        if (n == 0) {
            return 0;
        }
        if (n % 2 == 1) {
            return centers.get(n / 2);
        }
        return (centers.get(n / 2 - 1) + centers.get(n / 2)) / 2.0;
    }
}
