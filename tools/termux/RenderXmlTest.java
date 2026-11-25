import com.android.ide.common.rendering.api.ActionBarCallback;
import com.android.ide.common.rendering.api.AdapterBinding;
import com.android.ide.common.rendering.api.AssetRepository;
import com.android.ide.common.rendering.api.HardwareConfig;
import com.android.ide.common.rendering.api.ILayoutLog;
import com.android.ide.common.rendering.api.ILayoutPullParser;
import com.android.ide.common.rendering.api.LayoutlibCallback;
import com.android.ide.common.rendering.api.RenderResources;
import com.android.ide.common.rendering.api.RenderSession;
import com.android.ide.common.rendering.api.ResourceNamespace;
import com.android.ide.common.rendering.api.ResourceReference;
import com.android.ide.common.rendering.api.ResourceValue;
import com.android.ide.common.rendering.api.Result;
import com.android.ide.common.rendering.api.SessionParams;
import com.android.ide.common.rendering.api.ViewInfo;
import com.android.ide.common.resources.ResourceRepository;
import com.android.ide.common.resources.ResourceRepositoryUtil;
import com.android.ide.common.resources.ResourceResolver;
import com.android.ide.common.resources.ResourceValueMap;
import com.android.ide.common.resources.configuration.DensityQualifier;
import com.android.ide.common.resources.configuration.FolderConfiguration;
import com.android.ide.common.resources.configuration.LocaleQualifier;
import com.android.ide.common.resources.configuration.NightModeQualifier;
import com.android.ide.common.resources.configuration.ScreenDimensionQualifier;
import com.android.ide.common.resources.configuration.ScreenOrientationQualifier;
import com.android.ide.common.resources.configuration.ScreenRatioQualifier;
import com.android.ide.common.resources.configuration.ScreenSizeQualifier;
import com.android.ide.common.resources.configuration.UiModeQualifier;
import com.android.layoutlib.bridge.Bridge;
import com.android.resources.Density;
import com.android.resources.NightMode;
import com.android.resources.ResourceType;
import com.android.resources.ScreenOrientation;
import com.android.resources.ScreenRatio;
import com.android.resources.ScreenSize;
import com.android.resources.UiMode;
import org.kxml2.io.KXmlParser;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xmlpull.v1.XmlPullParser;

import javax.imageio.ImageIO;
import javax.xml.parsers.DocumentBuilderFactory;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

public class RenderXmlTest {
    private static class SimpleLayoutPullParser extends KXmlParser implements ILayoutPullParser {
        SimpleLayoutPullParser(File xmlFile) throws Exception {
            setFeature(FEATURE_PROCESS_NAMESPACES, true);
            setInput(new FileInputStream(xmlFile), StandardCharsets.UTF_8.name());
        }

        @Override
        public Object getViewCookie() {
            String name = getName();
            if (name == null) {
                return null;
            }
            String id = getAttributeValue("http://schemas.android.com/apk/res/android", "id");
            return id != null ? name + " [" + id + "]" : name;
        }

        @Override
        public ResourceNamespace getLayoutNamespace() {
            return ResourceNamespace.RES_AUTO;
        }
    }

    private static class MinimalCallback extends LayoutlibCallback {
        private final ActionBarCallback mActionBar = new ActionBarCallback();
        private final Map<ResourceReference, Integer> mIds = new HashMap<>();
        private final Map<Integer, ResourceReference> mRevIds = new HashMap<>();
        private int mNextId = 0x7f000001;

        @Override
        public Object loadView(String name, Class[] constructorSignature, Object[] constructorArgs)
                throws Exception {
            Class<?> cls = Class.forName(name);
            var ctor = cls.getConstructor(constructorSignature);
            ctor.setAccessible(true);
            return ctor.newInstance(constructorArgs);
        }

        @Override
        public ResourceReference resolveResourceId(int id) {
            return mRevIds.get(id);
        }

        @Override
        public int getOrGenerateResourceId(ResourceReference resource) {
            Integer existing = mIds.get(resource);
            if (existing != null) {
                return existing;
            }
            int id = mNextId++;
            mIds.put(resource, id);
            mRevIds.put(id, resource);
            return id;
        }

        @Override
        public ILayoutPullParser getParser(ResourceValue layoutResource) {
            return null;
        }

        @Override
        public AdapterBinding getAdapterBinding(Object viewObject, Map<String, String> attributes) {
            return null;
        }

        @Override
        public ActionBarCallback getActionBarCallback() {
            return mActionBar;
        }

        @Override
        public XmlPullParser createXmlParserForPsiFile(String fileName) {
            return null;
        }

        @Override
        public XmlPullParser createXmlParserForFile(String fileName) {
            try {
                KXmlParser p = new KXmlParser();
                p.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, true);
                p.setInput(new FileInputStream(fileName), StandardCharsets.UTF_8.name());
                return p;
            } catch (Exception e) {
                return null;
            }
        }

        @Override
        public XmlPullParser createXmlParser() {
            return new KXmlParser();
        }

        @Override
        public String getApplicationId() {
            return "com.termux.layoutlib.test";
        }

        @Override
        public String getResourcePackage() {
            return "com.termux.layoutlib.test";
        }
    }

    private static Map<String, Map<String, Integer>> parseEnumMap(File resSource) {
        Map<String, Map<String, Integer>> map = new HashMap<>();
        if (resSource == null || !resSource.exists()) {
            return map;
        }
        try {
            Document doc = null;
            DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
            if (resSource.isDirectory()) {
                File attrsXml = new File(resSource, "values/attrs.xml");
                if (attrsXml.isFile()) {
                    doc = dbf.newDocumentBuilder().parse(attrsXml);
                }
            } else if (resSource.isFile() && resSource.getName().endsWith(".jar")) {
                try (ZipFile zf = new ZipFile(resSource)) {
                    ZipEntry ze = zf.getEntry("res/values/attrs.xml");
                    if (ze == null) ze = zf.getEntry("values/attrs.xml");
                    if (ze != null) {
                        try (InputStream is = zf.getInputStream(ze)) {
                            doc = dbf.newDocumentBuilder().parse(is);
                        }
                    }
                }
            } else if (resSource.isFile()) {
                doc = dbf.newDocumentBuilder().parse(resSource);
            }
            if (doc == null) {
                return map;
            }
            NodeList attrs = doc.getElementsByTagName("attr");
            for (int i = 0; i < attrs.getLength(); i++) {
                Element attrEl = (Element) attrs.item(i);
                String attrName = attrEl.getAttribute("name");
                if (attrName == null || attrName.isEmpty()) continue;
                for (String tag : new String[]{"enum", "flag"}) {
                    NodeList items = attrEl.getElementsByTagName(tag);
                    for (int j = 0; j < items.getLength(); j++) {
                        Element el = (Element) items.item(j);
                        String n = el.getAttribute("name");
                        String v = el.getAttribute("value");
                        if (!n.isEmpty() && !v.isEmpty()) {
                            int val = (int) (long) Long.decode(v);
                            map.computeIfAbsent(attrName, k -> new HashMap<>()).put(n, val);
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("[warn] attrs.xml parse error: " + e.getMessage());
        }
        return map;
    }

    private static Map<String, String> loadBuildProps(File propFile) {
        Map<String, String> map = new HashMap<>();
        if (propFile != null && propFile.isFile()) {
            try (FileInputStream fis = new FileInputStream(propFile)) {
                Properties p = new Properties();
                p.load(fis);
                for (String k : p.stringPropertyNames()) {
                    map.put(k, p.getProperty(k));
                }
            } catch (Exception e) {
                System.err.println("[warn] build.prop load error: " + e.getMessage());
            }
        }
        // Bridge.setSystemProperties() explicitly sets these three ro.* keys afterward.
        map.remove("ro.icu.data.path");
        map.remove("ro.hyphen.data.dir");
        map.remove("ro.keyboard.paths");

        if (map.getOrDefault("ro.product.cpu.abilist64", "").isEmpty()) {
            map.put("ro.product.cpu.abilist64", "arm64-v8a");
        }
        if (map.getOrDefault("ro.product.cpu.abilist", "").isEmpty()) {
            map.put("ro.product.cpu.abilist", "arm64-v8a");
        }
        map.putIfAbsent("ro.product.cpu.abilist32", "");
        map.putIfAbsent("ro.product.cpu.abi", "arm64-v8a");
        map.putIfAbsent("ro.product.brand", "Android");
        map.putIfAbsent("ro.product.device", "layoutlib");
        map.putIfAbsent("ro.product.manufacturer", "Android");
        map.putIfAbsent("ro.product.model", "Layoutlib");
        map.putIfAbsent("ro.product.name", "layoutlib");
        map.putIfAbsent("ro.product.locale", "en-US");
        map.putIfAbsent("ro.build.id", "MAIN");
        map.putIfAbsent("ro.build.tags", "release-keys");
        map.putIfAbsent("ro.build.type", "user");
        map.putIfAbsent("ro.build.date", "Thu Jan 01 00:00:00 GMT 2026");
        map.putIfAbsent("ro.build.date.utc", "1767225600");
        map.putIfAbsent("ro.build.version.incremental", "eng.layoutlib");
        map.putIfAbsent("ro.build.version.sdk", "36");
        map.putIfAbsent("ro.build.version.sdk_full", "36.0");
        map.putIfAbsent("ro.build.version.preview_sdk", "0");
        map.putIfAbsent("ro.build.version.codename", "REL");
        map.putIfAbsent("ro.build.version.all_codenames", "REL");
        map.putIfAbsent("ro.build.version.known_codenames", "REL");
        map.putIfAbsent("ro.build.version.release", "17");
        map.putIfAbsent("ro.build.version.release_or_codename", "17");
        map.putIfAbsent("ro.build.version.security_patch", "2026-01-01");
        map.putIfAbsent("ro.build.version.min_supported_target_sdk", "28");
        map.putIfAbsent("ro.build.characteristics", "default");
        map.putIfAbsent("ro.hwui.max_texture_allocation_size", "104857600");
        return map;
    }

    private static File findFirstExisting(File... candidates) {
        for (File f : candidates) {
            if (f != null && f.exists()) return f;
        }
        return null;
    }

    private static RenderResources loadFrameworkResources(File resDir, String themeName) throws Exception {
        if (resDir == null || !resDir.exists()) {
            return null;
        }
        String[] repoClasses = new String[]{
                "com.android.resources.aar.FrameworkResourceRepository",
                "com.android.tools.res.FrameworkResourceRepository"
        };
        ResourceRepository frameworkRepo = null;
        for (String clsName : repoClasses) {
            try {
                Class<?> repoCls = Class.forName(clsName);
                for (Method m : repoCls.getMethods()) {
                    if (!m.getName().equals("create")) continue;
                    Class<?>[] pts = m.getParameterTypes();
                    if (pts.length == 4 && pts[0] == Path.class && pts[1] == Set.class && pts[3] == boolean.class) {
                        frameworkRepo = (ResourceRepository) m.invoke(
                                null, resDir.getAbsoluteFile().toPath(), Collections.emptySet(), null, true);
                        break;
                    } else if (pts.length == 3 && pts[0] == Path.class && pts[1] == Set.class) {
                        frameworkRepo = (ResourceRepository) m.invoke(
                                null, resDir.getAbsoluteFile().toPath(), Collections.emptySet(), null);
                        break;
                    }
                }
                if (frameworkRepo != null) break;
            } catch (ClassNotFoundException ignored) {
            }
        }
        if (frameworkRepo == null) {
            return null;
        }

        FolderConfiguration config = FolderConfiguration.createDefault();
        config.setDensityQualifier(new DensityQualifier(Density.XXHIGH));
        config.setScreenDimensionQualifier(new ScreenDimensionQualifier(1920, 1080));
        config.setScreenRatioQualifier(new ScreenRatioQualifier(ScreenRatio.NOTLONG));
        config.setScreenSizeQualifier(new ScreenSizeQualifier(ScreenSize.NORMAL));
        config.setScreenOrientationQualifier(new ScreenOrientationQualifier(ScreenOrientation.PORTRAIT));
        config.setUiModeQualifier(new UiModeQualifier(UiMode.NORMAL));
        config.setNightModeQualifier(new NightModeQualifier(NightMode.NOTNIGHT));
        config.setLocaleQualifier(new LocaleQualifier("en"));
        config.updateScreenWidthAndHeight();

        Map<ResourceType, ResourceValueMap> fwRes =
                ResourceRepositoryUtil.getConfiguredResources(frameworkRepo, config).row(ResourceNamespace.ANDROID);
        Map<ResourceNamespace, Map<ResourceType, ResourceValueMap>> allRes = new HashMap<>();
        allRes.put(ResourceNamespace.ANDROID, fwRes);

        return ResourceResolver.create(
                allRes, new ResourceReference(ResourceNamespace.ANDROID, ResourceType.STYLE, themeName));
    }

    public static void main(String[] args) throws Exception {
        String xmlPath = null;
        String outPath = "test_render.png";
        String detailsPath = null;
        String dataDirPath = null;
        String resDirPath = null;
        String fontDirPath = null;
        String hyphenDirPath = null;
        String nativeDirPath = "/data/data/com.termux/files/usr/lib/layoutlib";
        String icuPath = null;
        String themeName = "Theme.Material.Light.NoActionBar";
        int width = 1080;
        int height = 1920;

        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--xml" -> xmlPath = args[++i];
                case "--out" -> outPath = args[++i];
                case "--details" -> detailsPath = args[++i];
                case "--data-dir" -> dataDirPath = args[++i];
                case "--res-dir" -> resDirPath = args[++i];
                case "--font-dir" -> fontDirPath = args[++i];
                case "--hyphen-dir" -> hyphenDirPath = args[++i];
                case "--native-dir" -> nativeDirPath = args[++i];
                case "--icu" -> icuPath = args[++i];
                case "--theme" -> themeName = args[++i];
                case "--width" -> width = Integer.parseInt(args[++i]);
                case "--height" -> height = Integer.parseInt(args[++i]);
                default -> {
                    if (xmlPath == null) xmlPath = args[i];
                }
            }
        }

        if (xmlPath == null || (dataDirPath == null && resDirPath == null)) {
            System.err.println("Usage: RenderXmlTest --data-dir <layoutlib/data> --xml <layout.xml> [--out out.png] [--res-dir <res>] [--font-dir <fonts>] [--icu <icudt.dat>]");
            System.exit(2);
        }

        File dataDir = dataDirPath != null ? new File(dataDirPath) : null;
        File resDir = resDirPath != null ? new File(resDirPath) : findFirstExisting(
                dataDir != null ? new File(dataDir, "res") : null,
                dataDir != null ? new File(dataDir, "framework_res.jar") : null);
        File fontDir = fontDirPath != null ? new File(fontDirPath) : findFirstExisting(
                dataDir != null ? new File(dataDir, "fonts") : null,
                dataDir != null ? new File(dataDir.getParentFile(), "fonts") : null,
                new File("/system/fonts"));
        File hyphenDir = hyphenDirPath != null ? new File(hyphenDirPath) : findFirstExisting(
                dataDir != null ? new File(dataDir, "hyphen-data") : null,
                dataDir != null ? new File(dataDir, "hyphen") : null);
        File buildProp = findFirstExisting(
                dataDir != null ? new File(dataDir, "build.prop") : null,
                dataDir != null ? new File(dataDir, "layoutlib-build.prop") : null,
                (resDir != null && resDir.getParentFile() != null && resDir.getParentFile().getParentFile() != null)
                        ? new File(resDir.getParentFile().getParentFile(), "build.prop") : null);
        Map<String, Map<String, Integer>> enumMap = parseEnumMap(resDir);

        if (icuPath == null) {
            if (dataDir != null) {
                File icuDir = new File(dataDir, "icu");
                if (icuDir.isDirectory()) {
                    File[] dats = icuDir.listFiles((d, name) -> name.startsWith("icudt") && name.endsWith(".dat"));
                    if (dats != null && dats.length > 0) icuPath = dats[0].getAbsolutePath();
                }
            }
            if (icuPath == null) {
                File apexIcu = new File("/apex/com.android.i18n/etc/icu");
                if (apexIcu.isDirectory()) {
                    File[] dats = apexIcu.listFiles((d, name) -> name.startsWith("icudt") && name.endsWith(".dat"));
                    if (dats != null && dats.length > 0) icuPath = dats[0].getAbsolutePath();
                }
            }
        }
        if (icuPath == null || !new File(icuPath).isFile()) {
            throw new IllegalStateException("Could not find ICU data file (icudt*.dat). Pass --icu <path>.");
        }

        ILayoutLog log = new ILayoutLog() {
            @Override
            public void error(String tag, String message, Throwable throwable, Object viewCookie, Object data) {
                System.err.println("[ERROR " + tag + "] " + message);
                if (throwable != null) throwable.printStackTrace(System.err);
            }

            @Override
            public void warning(String tag, String message, Object viewCookie, Object data) {
                System.err.println("[WARN " + tag + "] " + message);
            }

            @Override
            public void logAndroidFramework(int priority, String tag, String message) {
                if (priority >= 5) {
                    System.out.println("[Framework p=" + priority + " " + tag + "] " + message);
                }
            }
        };

        Bridge bridge = new Bridge();
        Map<String, String> buildProps = loadBuildProps(buildProp);
        String hyphenPath = hyphenDir != null ? hyphenDir.getAbsolutePath() : "";
        String[] keyboardPaths = new String[0];
        boolean initOk = false;
        Method init8 = null;
        Method init7 = null;
        for (Method m : bridge.getClass().getMethods()) {
            if (!m.getName().equals("init")) continue;
            Class<?>[] pts = m.getParameterTypes();
            if (pts.length == 8 && pts[4] == String.class) {
                init8 = m;
            } else if (pts.length == 7 && pts[4] == String[].class) {
                init7 = m;
            }
        }
        if (init8 != null) {
            initOk = (Boolean) init8.invoke(
                    bridge, buildProps, fontDir, nativeDirPath, icuPath, hyphenPath, keyboardPaths, enumMap, log);
        } else if (init7 != null) {
            initOk = (Boolean) init7.invoke(
                    bridge, buildProps, fontDir, nativeDirPath, icuPath, keyboardPaths, enumMap, log);
        } else {
            throw new IllegalStateException("No compatible Bridge.init(...) overload found on " + bridge.getClass());
        }
        if (!initOk) {
            throw new IllegalStateException("Bridge.init() returned false!");
        }
        System.out.println("[ok] Bridge.init() succeeded with nativeDir=" + nativeDirPath);

        RenderResources renderResources = loadFrameworkResources(resDir, themeName);
        if (renderResources == null) {
            throw new IllegalStateException("Could not load framework resources from " + resDir);
        }

        HardwareConfig hw = new HardwareConfig(
                width, height, Density.XXHIGH, 445, 445, ScreenSize.NORMAL,
                width > height ? ScreenOrientation.LANDSCAPE : ScreenOrientation.PORTRAIT,
                null, true);

        SessionParams params = new SessionParams(
                new SimpleLayoutPullParser(new File(xmlPath)),
                SessionParams.RenderingMode.NORMAL,
                null,
                hw,
                renderResources,
                new MinimalCallback(),
                30,
                36,
                log,
                36
        );

        params.setExtendedViewInfoMode(true);
        params.setTimeout(50_000L);
        params.setAssetRepository(new AssetRepository());
        try {
            Class<?> flagsCls = Class.forName(
                    "com.android.layoutlib.bridge.android.RenderParamsFlags",
                    false,
                    bridge.getClass().getClassLoader());
            @SuppressWarnings("unchecked")
            SessionParams.Key<String> maskKey = (SessionParams.Key<String>)
                    flagsCls.getField("FLAG_KEY_ADAPTIVE_ICON_MASK_PATH").get(null);
            params.setFlag(maskKey,
                    "M50,0 C10,0 0,10 0,50 0,90 10,100 50,100 90,100 100,90 100,50 100,10 90,0 50,0 Z");
        } catch (Throwable ignored) {
        }

        long t0 = System.nanoTime();
        RenderSession session = bridge.createSession(params);
        AutoCloseable recyclableCloseable = null;
        try {
            Result res = session != null ? session.getResult() : null;
            if (res == null || !res.isSuccess()) {
                if (res != null && res.getException() != null) res.getException().printStackTrace(System.err);
                throw new IllegalStateException("Layout createSession failed: "
                        + (res != null ? res.getStatus() + " " + res.getErrorMessage() : "null result"));
            }

            BufferedImage img = null;
            Object recObj = tryGetRecyclableImage(session);
            if (recObj != null) {
                img = extractBufferedImage(recObj);
                if (img != null) {
                    if (recObj instanceof AutoCloseable ac) recyclableCloseable = ac;
                } else if (recObj instanceof AutoCloseable ac) {
                    try { ac.close(); } catch (Throwable ignored) {}
                }
            }
            if (img == null) {
                img = session.getImage();
            }
            if (img == null) {
                res = session.render(50_000L);
                if (res == null || !res.isSuccess()) {
                    if (res != null && res.getException() != null) res.getException().printStackTrace(System.err);
                    throw new IllegalStateException("Layout render() failed: "
                            + (res != null ? res.getStatus() + " " + res.getErrorMessage() : "null result"));
                }
                recObj = tryGetRecyclableImage(session);
                if (recObj != null) {
                    if (recObj instanceof AutoCloseable ac) recyclableCloseable = ac;
                    img = extractBufferedImage(recObj);
                }
                if (img == null) {
                    img = session.getImage();
                }
            }
            if (img == null) {
                throw new IllegalStateException(
                        "Rendered image was null! sessionClass=" + session.getClass().getName()
                                + " status=" + res.getStatus()
                                + " msg=" + res.getErrorMessage()
                                + " recObj=" + recObj
                                + " rootViews=" + (session.getRootViews() != null ? session.getRootViews().size() : -1)
                                + " sysRootViews=" + (session.getSystemRootViews() != null ? session.getSystemRootViews().size() : -1));
            }
            File outFile = new File(outPath);
            if (outFile.getParentFile() != null) Files.createDirectories(outFile.getParentFile().toPath());
            ImageIO.write(img, "png", outFile);
            long ms = (System.nanoTime() - t0) / 1_000_000L;
            System.out.printf("[PASS] Rendered %s -> %s (%dx%d PNG, %d bytes, %d ms)%n",
                    xmlPath, outFile.getAbsolutePath(), img.getWidth(), img.getHeight(), outFile.length(), ms);
            if (detailsPath != null && !detailsPath.isEmpty()) {
                String report = buildRenderReport(
                        xmlPath, outFile, img, ms, res, session, recObj,
                        themeName, width, height, nativeDirPath, icuPath,
                        fontDir != null ? fontDir.getAbsolutePath() : "",
                        resDir != null ? resDir.getAbsolutePath() : "",
                        buildProps);
                File detailsFile = new File(detailsPath);
                if (detailsFile.getParentFile() != null) Files.createDirectories(detailsFile.getParentFile().toPath());
                Files.writeString(detailsFile.toPath(), report, StandardCharsets.UTF_8);
                System.out.println("[PASS] Details saved -> " + detailsFile.getAbsolutePath());
                System.out.println(report);
            }
        } finally {
            if (recyclableCloseable != null) {
                try {
                    recyclableCloseable.close();
                } catch (Throwable ignored) {
                }
            }
            if (session != null) {
                try {
                    session.dispose();
                } catch (Throwable ignored) {
                }
            }
        }
        System.exit(0);
    }

    private static Object tryGetRecyclableImage(RenderSession session) {
        try {
            Method m = RenderSession.class.getMethod("getRecyclableImage");
            return m.invoke(session);
        } catch (NoSuchMethodException e) {
            return null;
        } catch (Throwable t) {
            System.err.println("[warn] getRecyclableImage() failed: " + t);
            return null;
        }
    }

    private static BufferedImage extractBufferedImage(Object recImg) {
        if (recImg == null) return null;
        try {
            Class<?> recCls = Class.forName(
                    "com.android.ide.common.rendering.api.RecyclableImage",
                    false,
                    recImg.getClass().getClassLoader());
            try {
                Method isValidM = recCls.getMethod("isValid");
                if (!Boolean.TRUE.equals(isValidM.invoke(recImg))) {
                    return null;
                }
            } catch (NoSuchMethodException ignored) {
            }
            for (String mName : new String[]{"getCopy", "getImage"}) {
                try {
                    Method m = recCls.getMethod(mName);
                    BufferedImage bi = (BufferedImage) m.invoke(recImg);
                    if (bi != null) return bi;
                } catch (NoSuchMethodException ignored) {
                }
            }
        } catch (ClassNotFoundException ignored) {
        } catch (Throwable t) {
            System.err.println("[warn] RecyclableImage reflection failed: " + t);
        }
        if (Modifier.isPublic(recImg.getClass().getModifiers())) {
            for (String mName : new String[]{"getImage", "getCopy"}) {
                try {
                    Method m = recImg.getClass().getMethod(mName);
                    BufferedImage bi = (BufferedImage) m.invoke(recImg);
                    if (bi != null) return bi;
                } catch (Throwable ignored) {
                }
            }
        }
        return null;
    }

    private static String buildRenderReport(
            String xmlPath,
            File outFile,
            BufferedImage img,
            long elapsedMs,
            Result res,
            RenderSession session,
            Object recObj,
            String themeName,
            int targetWidth,
            int targetHeight,
            String nativeDirPath,
            String icuPath,
            String fontDirPath,
            String resDirPath,
            Map<String, String> buildProps) {
        StringBuilder sb = new StringBuilder();
        sb.append("=== Layoutlib Render Details Report ===\n");
        sb.append("xml_path         : ").append(xmlPath).append('\n');
        sb.append("png_path         : ").append(outFile.getAbsolutePath()).append('\n');
        sb.append("png_size_bytes   : ").append(outFile.length()).append('\n');
        sb.append("render_time_ms   : ").append(elapsedMs).append('\n');
        sb.append("result_status    : ").append(res.getStatus()).append('\n');
        sb.append("session_class    : ").append(session.getClass().getName()).append('\n');
        sb.append("image_source     : ").append(recObj != null ? recObj.getClass().getName() : "RenderSession.getImage()").append('\n');
        sb.append("theme            : @android:style/").append(themeName).append('\n');
        sb.append("viewport         : ").append(targetWidth).append('x').append(targetHeight).append('\n');
        sb.append("bitmap_dims      : ").append(img.getWidth()).append('x').append(img.getHeight()).append('\n');
        sb.append("bitmap_type      : ").append(img.getType()).append(" (BufferedImage.TYPE_INT_ARGB_PRE=3)\n");
        sb.append("native_dir       : ").append(nativeDirPath).append('\n');
        sb.append("icu_data         : ").append(icuPath).append('\n');
        sb.append("font_dir         : ").append(fontDirPath).append('\n');
        sb.append("res_dir          : ").append(resDirPath).append('\n');
        sb.append("prop_sdk_int     : ").append(buildProps.get("ro.build.version.sdk"))
                .append(" (release=").append(buildProps.get("ro.build.version.release"))
                .append(", abi=").append(buildProps.get("ro.product.cpu.abilist64")).append(")\n");

        int w = img.getWidth();
        int h = img.getHeight();
        long totalPx = (long) w * h;
        long opaquePx = 0;
        long transparentPx = 0;
        Map<Integer, Long> colorCounts = new HashMap<>();
        int[] row = new int[w];
        for (int y = 0; y < h; y++) {
            img.getRGB(0, y, w, 1, row, 0, w);
            for (int x = 0; x < w; x++) {
                int argb = row[x];
                int a = (argb >>> 24) & 0xff;
                if (a == 255) opaquePx++;
                else if (a == 0) transparentPx++;
                colorCounts.merge(argb, 1L, Long::sum);
            }
        }
        sb.append("pixel_stats      : total=").append(totalPx)
                .append(", opaque=").append(opaquePx)
                .append(", transparent=").append(transparentPx)
                .append(", unique_argb=").append(colorCounts.size()).append('\n');
        sb.append("top_argb_colors  :");
        colorCounts.entrySet().stream()
                .sorted((a, b) -> Long.compare(b.getValue(), a.getValue()))
                .limit(8)
                .forEach(e -> sb.append(String.format(" #%08X(%d)", e.getKey(), e.getValue())));
        sb.append("\n\n");

        List<ViewInfo> rootViews = session.getRootViews();
        sb.append("=== Content Root Views (").append(rootViews != null ? rootViews.size() : 0).append(") ===\n");
        if (rootViews != null) {
            for (ViewInfo vi : rootViews) {
                dumpViewTree(sb, vi, 0);
            }
        }
        sb.append('\n');

        List<ViewInfo> sysViews = session.getSystemRootViews();
        sb.append("=== System Decor & Window Views (").append(sysViews != null ? sysViews.size() : 0).append(") ===\n");
        if (sysViews != null) {
            for (ViewInfo vi : sysViews) {
                dumpViewTree(sb, vi, 0);
            }
        }
        return sb.toString();
    }

    private static void dumpViewTree(StringBuilder sb, ViewInfo vi, int depth) {
        if (vi == null) return;
        for (int i = 0; i < depth; i++) sb.append("  ");
        int w = vi.getRight() - vi.getLeft();
        int h = vi.getBottom() - vi.getTop();
        sb.append("- ").append(vi.getClassName());
        if (vi.getCookie() != null) {
            sb.append(" {").append(vi.getCookie()).append('}');
        }
        sb.append(String.format(" bounds=[%d,%d,%d,%d] size=%dx%d",
                vi.getLeft(), vi.getTop(), vi.getRight(), vi.getBottom(), w, h));
        if (vi.getBaseLine() > 0) {
            sb.append(" baseline=").append(vi.getBaseLine());
        }
        if (vi.getViewType() != null) {
            sb.append(" type=").append(vi.getViewType());
        }
        Object viewObj = vi.getViewObject();
        if (viewObj != null) {
            try {
                Method getText = viewObj.getClass().getMethod("getText");
                Object txt = getText.invoke(viewObj);
                if (txt != null && !txt.toString().isEmpty()) {
                    String s = txt.toString().replace('\n', ' ');
                    if (s.length() > 48) s = s.substring(0, 48) + "...";
                    sb.append(" text=\"").append(s).append('"');
                }
            } catch (Throwable ignored) {
            }
        }
        sb.append('\n');
        List<ViewInfo> children = vi.getChildren();
        if (children != null) {
            for (ViewInfo child : children) {
                dumpViewTree(sb, child, depth + 1);
            }
        }
    }
}
