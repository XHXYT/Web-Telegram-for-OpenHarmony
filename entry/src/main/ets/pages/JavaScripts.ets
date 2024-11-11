//此脚本改编自 俺的手机视频脚本(https://greasyfork.org/zh-CN/scripts/456542-%E4%BF%BA%E7%9A%84%E6%89%8B%E6%9C%BA%E8%A7%86%E9%A2%91%E8%84%9A%E6%9C%AC)
let jsStr: string = "" +
  "\n" +
  "\n" +
  "(function () {\n" +
  "    'use strict';\n" +
  "    if (navigator.userAgent.search(\"Android\") < 0) {\n" +
  "        //return;\n" +
  "    }\n" +
  "    //放开iframe全屏\n" +
  "    let iframes = document.getElementsByTagName(\"iframe\");\n" +
  "    for (let iframe of iframes) {\n" +
  "        iframe.allowFullscreen = true;\n" +
  "    }\n" +
  "    //部分网站阻止视频操作层触摸事件传播，需要指定监听目标，默认是document\n" +
  "    //注意，对少数iframe内视频，广告插件或使此脚本不起作用\n" +
  "    let listenTarget = document;\n" +
  "    //youtube使用无刷新网页，需要监听地址变化重新监听操控层\n" +
  "    if (window.location.host === \"m.youtube.com\") {\n" +
  "        let refresh = function () {\n" +
  "            console.log(\"俺的手机视频脚本：页面刷新...\");\n" +
  "            //youtube视频在脚本执行时还没加载，需要个定时器循环获取状态\n" +
  "            if (window.location.href.search(\"watch\") >= 0) {\n" +
  "                let waitForVideo = function () {\n" +
  "                    console.log(\"俺的手机视频脚本：正在获取视频...\");\n" +
  "                    //特定的视频操控层\n" +
  "                    let videos = document.getElementsByTagName(\"video\");\n" +
  "                    let listenTargetArray = document.getElementsByClassName(\"player-controls-background\");\n" +
  "                    if (videos.length > 0) {\n" +
  "                        let video = videos[0];\n" +
  "                        //非静音播放中\n" +
  "                        if (video.readyState > 1 && !video.paused && !video.muted) {\n" +
  "                            listenTarget = listenTargetArray[0];\n" +
  "                            //防止重复添加\n" +
  "                            if (listenTarget.getAttribute(\"me_video_js\")) {\n" +
  "                                return;\n" +
  "                            }\n" +
  "                            listenTarget.setAttribute(\"me_video_js\", \"me_video_js\");\n" +
  "                            //视频已加载\n" +
  "                            console.log(\"俺的手机视频脚本：开始监听手势。\");\n" +
  "                            listen();\n" +
  "                            return;\n" +
  "                        }\n" +
  "                    }\n" +
  "                    setTimeout(waitForVideo, 500);\n" +
  "                }\n" +
  "                waitForVideo();\n" +
  "            }\n" +
  "        };\n" +
  "        refresh();\n" +
  "        window.addEventListener(\"urlchange\", refresh);\n" +
  "    }\n" +
  "    //通用\n" +
  "    listen();\n" +
  "\n" +
  "    function listen() {\n" +
  "        if (listenTarget.tagName/*监听的是元素*/) {\n" +
  "            //做个标记方便调试\n" +
  "            listenTarget.setAttribute(\"listen_mark\", true);\n" +
  "        }\n" +
  "        //对视频的查找与控制都是在每次touchstart后重新执行的\n" +
  "        //虽然这样更消耗性能，但是对不同的网站兼容性更强\n" +
  "        listenTarget.addEventListener(\"touchstart\", (e) => {\n" +
  "            //为了代码逻辑在普通视频与iframe内视频的通用性，分别使用了clientX和screenY\n" +
  "            let startX;\n" +
  "            let startY;\n" +
  "            let endX;\n" +
  "            let endY;\n" +
  "            //多根手指不做响应\n" +
  "            if (e.touches.length === 1) {\n" +
  "                //在全屏时，不对边缘5%的区域做响应\n" +
  "                let screenX = e.touches[0].screenX;\n" +
  "                let screenY = e.touches[0].screenY;\n" +
  "                if (document.fullscreenElement) {\n" +
  "                    if (screenX < screen.width * 0.05 || screenX > screen.width * 0.95 ||\n" +
  "                        screenY < screen.height * 0.05 || screenY > screen.height * 0.95)\n" +
  "                        return;\n" +
  "                }\n" +
  "                //单指触摸，记录位置\n" +
  "                startX = Math.ceil(e.touches[0].clientX);\n" +
  "                startY = Math.ceil(screenY);\n" +
  "                endX = startX;\n" +
  "                endY = startY;\n" +
  "            } else return;\n" +
  "            let videoElement;\n" +
  "            //触摸的目标如果是视频或视频操控层，那他也是我们绑定手势的目标\n" +
  "            let target = e.target;\n" +
  "            //用于有操控层的网站，保存的是视频与操控层适当尺寸下的最大共同祖先节点，确认后需要在后代内搜索视频元素\n" +
  "            let biggestContainer;\n" +
  "            let targetWidth = target.clientWidth;\n" +
  "            let targetHeight = target.clientHeight;\n" +
  "            //所有大小合适的祖先节点最后一个为biggestContainer\n" +
  "            let suitParents = [];\n" +
  "            //用于判断是否含有包裹视频的a标签，需要禁止其被长按时呼出浏览器菜单\n" +
  "            let allParents = [];\n" +
  "            let temp = target;\n" +
  "            //用于抖音类网站，滚动高度超过阈值后，不再继续查找祖先\n" +
  "            let findAllSuitParent = false;\n" +
  "            //抖音类短视频网站，特点是视频操控层占据几乎整个屏幕\n" +
  "            let maybeTiktok = false;\n" +
  "            //用于短视频判断\n" +
  "            let scrollHeightOut = false;\n" +
  "            while (true) {\n" +
  "                temp = temp.parentElement;\n" +
  "                if (!temp/*或直接点击到html元素，他将没有父元素*/) {\n" +
  "                    return;\n" +
  "                }\n" +
  "                //allParents全部保存，用于判断是否存在a标签\n" +
  "                allParents.push(temp);\n" +
  "                if (!findAllSuitParent &&\n" +
  "                    temp.clientWidth > 0 &&\n" +
  "                    temp.clientWidth < targetWidth * 1.2 &&\n" +
  "                    temp.clientHeight > 0 &&\n" +
  "                    temp.clientHeight < targetHeight * 1.2) {\n" +
  "                    //用非全屏状态下scrollHeight来判断可以准确找到抖音类网站的合适视频容器\n" +
  "                    if (document.fullscreenElement) {\n" +
  "                        //全屏时视觉尺寸合适都可以用，youtube全屏就有滚动高度超出限制的元素\n" +
  "                        //suitParents保存适合的尺寸的祖先节点\n" +
  "                        suitParents.push(temp);\n" +
  "                    } else {\n" +
  "                        //非全屏时要判断一下滚动高度\n" +
  "                        if (temp.scrollHeight < targetHeight * 1.2) {\n" +
  "                            suitParents.push(temp);\n" +
  "                        } else {\n" +
  "                            findAllSuitParent = true;\n" +
  "                            scrollHeightOut = true;\n" +
  "                        }\n" +
  "                    }\n" +
  "                }\n" +
  "                //循环结束条件\n" +
  "                if (temp.tagName === \"BODY\" ||\n" +
  "                    temp.tagName === \"HTML\" ||\n" +
  "                    !temp.parentElement) {\n" +
  "                    //已找到所有符合条件的祖先节点，取最后一个\n" +
  "                    if (suitParents.length > 0) {\n" +
  "                        biggestContainer = suitParents[suitParents.length - 1];\n" +
  "                    }\n" +
  "                    //没有任何大小合适的祖先元素，且自身不是视频元素，那也肯定不是视频操控层\n" +
  "                    else if (target.tagName !== \"VIDEO\") {\n" +
  "                        return;\n" +
  "                    }\n" +
  "                    //gc\n" +
  "                    suitParents = null;\n" +
  "                    break;\n" +
  "                }\n" +
  "            }\n" +
  "            //当触摸的不是视频元素，可能是非视频相关组件，或视频的操控层\n" +
  "            if (target.tagName !== \"VIDEO\") {\n" +
  "                //尝试获取视频元素\n" +
  "                let videoArray = biggestContainer.getElementsByTagName(\"video\");\n" +
  "                if (videoArray.length > 0) {\n" +
  "                    videoElement = videoArray[0];\n" +
  "                    //找到视频元素后，可以判断是否可能是短视频\n" +
  "                    //非全屏状态下，非iframe内视频，若视频操作层或视频占据大半的屏幕，判断为短视频\n" +
  "                    //tiktok没有视频控件，判断这个防止有页面的预览视频铺满了屏幕，这一项只能判断到没有框架的视频\n" +
  "                    if (!document.fullscreenElement &&\n" +
  "                        top === window &&\n" +
  "                        !videoElement.controls &&\n" +
  "                        scrollHeightOut &&\n" +
  "                        target.clientHeight > window.innerHeight * 0.8) {\n" +
  "                        maybeTiktok = true;\n" +
  "                    }\n" +
  "                    //如果是视频外很大的容器绝非我们想要的\n" +
  "                    //操作层除了短视频没见过高度高视频这么多的，大概率不是视频操控层\n" +
  "                    let _videoWidth = videoElement.clientWidth;\n" +
  "                    let _videoHeight = videoElement.clientHeight;\n" +
  "                    if (!maybeTiktok && targetHeight > _videoHeight * 1.5) {\n" +
  "                        //不是合适的操作层\n" +
  "                        return;\n" +
  "                    }\n" +
  "                    if (videoArray.length > 1) {\n" +
  "                        console.log(\"触摸位置找到不止一个视频。\");\n" +
  "                    }\n" +
  "                } else {\n" +
  "                    //非视频相关组件\n" +
  "                    return;\n" +
  "                }\n" +
  "            }\n" +
  "            //触摸的是视频元素，则一切清晰明了\n" +
  "            else {\n" +
  "                videoElement = target;\n" +
  "            }\n" +
  "            //用于比较单击后，视频的播放状态，如果单击暂停，则恢复播放\n" +
  "            let playing = !videoElement.paused;\n" +
  "            //下面两个连通tiktok变量3个参数用于判断是否要执行touchmove事件处理器\n" +
  "            //小于30s当做预览视频，在网页上的视频列表可能存在，不要让他们影响网页滚动\n" +
  "            let sampleVideo = false;\n" +
  "            let videoReady = false;\n" +
  "            let videoReadyHandler = function () {\n" +
  "                videoReady = true;\n" +
  "                if (videoElement.duration < 30) {\n" +
  "                    sampleVideo = true;\n" +
  "                }\n" +
  "            };\n" +
  "            if (videoElement.readyState > 0) {\n" +
  "                videoReadyHandler();\n" +
  "            } else {\n" +
  "                videoElement.addEventListener(\"loadedmetadata\", videoReadyHandler, { once: true });\n" +
  "            }\n" +
  "            //一个合适尺寸的最近祖先元素用于显示手势信息与全屏按钮\n" +
  "            let componentContainer = findComponentContainer();\n" +
  "            //指示器元素\n" +
  "            let notice;\n" +
  "            //视频快进快退量\n" +
  "            let timeChange = 0;\n" +
  "            //1表示右滑快进，2表示左滑快退，方向一旦确认就无法更改\n" +
  "            let direction;\n" +
  "            //优化a标签导致的长按手势中断问题（许多网站的视频列表的预览视频都是由a标签包裹）\n" +
  "            makeTagAQuiet();\n" +
  "            //禁止长按视频呼出浏览器菜单，为长按倍速做准备（没有视频框架的视频需要）\n" +
  "            if (!videoElement.getAttribute(\"disable_contextmenu\")/*只添加一次监听器*/) {\n" +
  "                videoElement.addEventListener(\"contextmenu\", (e) => {\n" +
  "                    e.preventDefault();\n" +
  "                });\n" +
  "                videoElement.setAttribute(\"disable_contextmenu\", true);\n" +
  "            }\n" +
  "            //禁止图片长按呼出浏览器菜单和拖动（部分框架视频未播放时，触摸到的是预览图，抖音类播放时摸到的都是图片）\n" +
  "            if (target.tagName === \"IMG\") {\n" +
  "                target.draggable = false;\n" +
  "                if (!target.getAttribute(\"disable_contextmenu\")) {\n" +
  "                    target.addEventListener(\"contextmenu\", (e) => {\n" +
  "                        e.preventDefault();\n" +
  "                    });\n" +
  "                    target.setAttribute(\"disable_contextmenu\", true);\n" +
  "                }\n" +
  "            }\n" +
  "\n" +
  "            let haveControls = videoElement.controls;\n" +
  "            \n" +
  "            //长按倍速定时器\n" +
  "            let longPress = false;\n" +
  "            // 创建一个新的div元素用于显示通知\n" +
  "            notice = document.createElement(\"div\");\n" +
  "            notice.style.display = \"none\"; // 默认不显示\n" +
  "            notice.innerText = \"x4\"; // 设置通知内容\n" +
  "            document.body.appendChild(notice); // 将通知元素添加到body中\n" +
  "            // 长按相关变量\n" +
  "            let rateTimer;\n" +
  "            // 显示通知\n" +
  "            function showNotice() {\n" +
  "                notice.style.display = \"block\";\n" +
  "            }\n" +
  "            // 隐藏通知\n" +
  "            function hideNotice() {\n" +
  "                notice.style.display = \"none\";\n" +
  "            }\n" +
  "            // 触摸开始的处理函数\n" +
  "            function handleTouchStart() {\n" +
  "                rateTimer = setTimeout(() => {\n" +
  "                    videoElement.playbackRate = 4;\n" +
  "                    videoElement.controls = false;\n" +
  "                    target.removeEventListener(\"touchmove\", touchmoveHandler); \n" +
  "                    showNotice();\n" +
  "                    longPress = true;\n" +
  "                }, 800);\n" +
  "            }\n" +
  "            // 触摸结束的处理函数\n" +
  "            function handleTouchEnd() {\n" +
  "                clearTimeout(rateTimer);\n" +
  "                if (longPress) {\n" +
  "                    handleLongPressEnd();\n" +
  "                }\n" +
  "            }\n" +
  "            // 长按结束后的处理函数\n" +
  "            function handleLongPressEnd() {\n" +
  "                videoElement.playbackRate = 1; // 恢复正常播放速度\n" +
  "                videoElement.controls = true;\n" +
  "                target.addEventListener(\"touchmove\", touchmoveHandler); // 重新绑定触摸移动事件处理器\n" +
  "                hideNotice();\n" +
  "                longPress = false;\n" +
  "            }\n" +
  "            // 绑定触摸事件\n" +
  "            target.addEventListener(\"touchstart\", handleTouchStart);\n" +
  "            target.addEventListener(\"touchend\", handleTouchEnd);\n" +
  "            target.addEventListener(\"touchcancel\", handleTouchEnd);\n" +
  "\n" +
  "\n" +
  "            //有些网站预览视频位置实际在屏幕之外，需要加上平移的数值\n" +
  "            let screenWidth = screen.width;\n" +
  "            let componentMoveLeft = componentContainer.offsetLeft;\n" +
  "            let moveNum = Math.floor(componentMoveLeft * 1.1 / screenWidth);\n" +
  "            //添加指示器元素\n" +
  "            if (componentContainer) {\n" +
  "                notice = document.createElement(\"div\");\n" +
  "                let noticeWidth = 110;//未带单位，后面需要加单位\n" +
  "                let noticeHeight = 30;\n" +
  "                let noticeTop = Math.round(componentContainer.clientHeight / 6);\n" +
  "                let noticeLeft = Math.round(moveNum * screenWidth + componentContainer.clientWidth / 2 - noticeWidth / 2);\n" +
  "                notice.style.cssText = \"position:absolute;display:none;z-index:99999;\" +\n" +
  "                    \"text-align:center;opacity:0.5;background-color:black;color:white;\" +\n" +
  "                    \"font:16px/1.8 sans-serif;letter-spacing:normal;border-radius:4px;\";\n" +
  "                notice.style.width = noticeWidth + \"px\";\n" +
  "                notice.style.height = noticeHeight + \"px\";\n" +
  "                notice.style.left = noticeLeft + \"px\";\n" +
  "                notice.style.top = noticeTop + \"px\";\n" +
  "                componentContainer.appendChild(notice);\n" +
  "            } else {\n" +
  "                //怎么可能有视频没有div包着啊\n" +
  "                console.log(\"该视频没有可以用于给快进指示器定位的祖先元素。\");\n" +
  "            }\n" +
  "            //滑动流畅的关键1，passive为false代表处理器内调用preventDefault()不会被浏览器拒绝\n" +
  "            //mdn：文档级节点 Window、Document 和 Document.body默认是true，其他节点默认是false\n" +
  "            target.addEventListener(\"touchmove\", touchmoveHandler/*, {passive: false}*/);\n" +
  "            target.addEventListener(\"touchend\", () => {\n" +
  "                setTimeout(touchendHandler, 0);\n" +
  "            }, { once: true });\n" +
  "\n" +
  "            function makeTagAQuiet() {\n" +
  "                for (let element of allParents) {\n" +
  "                    if (element.tagName === \"A\" &&\n" +
  "                        !element.getAttribute(\"disable_menu_and_drag\")) {\n" +
  "                        //禁止长按菜单\n" +
  "                        element.addEventListener(\"contextmenu\", (e) => {\n" +
  "                            e.preventDefault();\n" +
  "                        });\n" +
  "                        //禁止长按拖动\n" +
  "                        element.draggable = false;\n" +
  "                        element.setAttribute(\"disable_menu_and_drag\", true);\n" +
  "                        //没有长按菜单，用target=\"_blank\"属性来平替\n" +
  "                        element.target = \"_blank\";\n" +
  "                        //不可能a标签嵌套a标签吧\n" +
  "                        break;\n" +
  "                    }\n" +
  "                }\n" +
  "                allParents = null;\n" +
  "            }\n" +
  "\n" +
  "            function findComponentContainer() {\n" +
  "                let temp = videoElement;\n" +
  "                while (true) {\n" +
  "                    //寻找最近的有长宽数值的祖先节点\n" +
  "                    if (temp.parentElement.clientWidth > 0 &&\n" +
  "                        temp.parentElement.clientHeight > 0) {\n" +
  "                        return temp.parentElement;\n" +
  "                    } else {\n" +
  "                        temp = temp.parentElement;\n" +
  "                    }\n" +
  "                }\n" +
  "            }\n" +
  "\n" +
  "            function getClearTimeChange(timeChange) {\n" +
  "                timeChange = Math.abs(timeChange);\n" +
  "                let minute = Math.floor(timeChange / 60);\n" +
  "                let second = timeChange % 60;\n" +
  "                return (minute === 0 ? \"\" : (minute + \"min\")) + second + \"s\";\n" +
  "            }\n" +
  "\n" +
  "            function touchmoveHandler(moveEvent) {\n" +
  "                //触摸屏幕后，0.8s内如果有移动，清除长按定时事件\n" +
  "                if (rateTimer) {\n" +
  "                    clearTimeout(rateTimer);\n" +
  "                    rateTimer = null;\n" +
  "                }\n" +
  "                if (maybeTiktok || sampleVideo || !videoReady) {\n" +
  "                    return;\n" +
  "                }\n" +
  "                //滑动流畅的关键2\n" +
  "                moveEvent.preventDefault();\n" +
  "                if (moveEvent.touches.length === 1) {\n" +
  "                    //仅支持单指触摸，记录位置\n" +
  "                    let temp = Math.ceil(moveEvent.touches[0].clientX);\n" +
  "                    //x轴没变化，y轴方向移动也会触发，要避免不必要的运算\n" +
  "                    if (temp === endX) {\n" +
  "                        return;\n" +
  "                    } else {\n" +
  "                        endX = temp;\n" +
  "                    }\n" +
  "                    endY = Math.ceil(moveEvent.touches[0].screenY);\n" +
  "                    //console.log(\"移动到\" + endX + \",\" + endY);\n" +
  "                }\n" +
  "                //由第一次移动确认手势方向，就不再变更\n" +
  "                //10个像素起\n" +
  "                if (endX > startX + 10) {\n" +
  "                    //快进\n" +
  "                    if (!direction) {\n" +
  "                        //首次移动，记录方向\n" +
  "                        direction = 1;\n" +
  "                    }\n" +
  "                    if (direction === 1) {\n" +
  "                        //方向未变化\n" +
  "                        timeChange = endX - startX - 10;\n" +
  "                    } else {\n" +
  "                        timeChange = 0;\n" +
  "                    }\n" +
  "                } else if (endX < startX - 10) {\n" +
  "                    //快退\n" +
  "                    if (!direction) {\n" +
  "                        //首次移动，记录方向\n" +
  "                        direction = 2;\n" +
  "                    }\n" +
  "                    if (direction === 2) {\n" +
  "                        //方向未变化\n" +
  "                        timeChange = endX - startX + 10;\n" +
  "                    } else {\n" +
  "                        timeChange = 0;\n" +
  "                    }\n" +
  "\n" +
  "                } else if (timeChange !== 0) {\n" +
  "                    timeChange = 0;\n" +
  "                } else {\n" +
  "                    return;\n" +
  "                }\n" +
  "                if (notice.style.display === \"none\" /*已经显示了就不管怎么滑动了*/ &&\n" +
  "                    Math.abs(endY - startY) > Math.abs(endX - startX)) {\n" +
  "                    //垂直滑动不显示\n" +
  "                    timeChange = 0;\n" +
  "                    return;\n" +
  "                }\n" +
  "                //未到阈值不显示\n" +
  "                if (direction) {\n" +
  "                    notice.style.display = \"block\";\n" +
  "                    notice.innerText = (direction === 1 ? \">>>\" : \"<<<\") + getClearTimeChange(timeChange);\n" +
  "                }\n" +
  "            }\n" +
  "\n" +
  "            function touchendHandler() {\n" +
  "                // 获取 sessionStorage 中的 'voiced' 值，并将其转换为布尔类型\n" +
  "                var thevoiced = sessionStorage.getItem(\"voiced\") === 'true';\n" +
  "\n" +
  "                // 根据 'voiced' 的值设置视频元素的 muted 属性\n" +
  "                if (thevoiced) {\n" +
  "                    videoElement.muted = false;\n" +
  "                } else {\n" +
  "                    videoElement.muted = true;\n" +
  "                }\n" +
  "                //所有非短视频自带的全视频区域的单击暂停，给他重新播放，手机不适合单击暂停，需要暂停的使用暂停按钮即可\n" +
  "                //带延迟是为了让网页自带的js先执行，videoElement.paused的状态才会判断准确\n" +
  "                setTimeout(() => {\n" +
  "                    if (playing && videoElement.paused && !maybeTiktok) {\n" +
  "                        videoElement.play();\n" +
  "                    }\n" +
  "                }, 200);\n" +
  "                //一般有chrome自带视频控件的就是没用框架的视频\n" +
  "                //需要替换全屏按钮，不然无法显示快进指示器\n" +
  "                //非长按后手指抬起时才添加全屏按钮\n" +
  "                if (!longPress && videoElement.controls && !document.fullscreenElement) {\n" +
  "                    let myFullscreenBtn = document.getElementById(\"myFullscreenBtn\");\n" +
  "                    if (!myFullscreenBtn) {\n" +
  "                        let btn = document.createElement(\"div\");\n" +
  "                        btn.style.cssText = \"z-index:9999999;position:absolute;\" +\n" +
  "                            \"display:block;width:50px;\" +\n" +
  "                            \"background-color:black;color:white;opacity:0.5;\" +\n" +
  "                            \"padding:5px 2px;font:16px/1.2 sans-serif;font-weight:bold;text-align:center;\" +\n" +
  "                            \"box-sizing:border-box;border:2px solid white;white-space:normal;\";\n" +
  "                        btn.innerText = \"点我全屏\";\n" +
  "                        btn.id = \"myFullscreenBtn\";\n" +
  "                        let divHeight = 50;\n" +
  "                        btn.style.height = divHeight + \"px\";\n" +
  "                        btn.style.top = Math.round(componentContainer.clientHeight / 2 - divHeight / 2 - 10) + \"px\";\n" +
  "                        btn.style.left = Math.round(moveNum * screenWidth + componentContainer.clientWidth * 5 / 7) + \"px\";\n" +
  "                        componentContainer.append(btn);\n" +
  "                        btn.addEventListener(\"touchstart\", async function () {\n" +
  "                            clean();\n" +
  "                            await componentContainer.requestFullscreen();\n" +
  "                        });\n" +
  "                        //屏蔽原生全屏按钮\n" +
  "                        videoElement.controlsList = [\"nofullscreen\"];\n" +
  "                        setTimeout(clean, 2000);\n" +
  "\n" +
  "                        function clean() {\n" +
  "                            let myFullscreenBtn = document.getElementById(\"myFullscreenBtn\");\n" +
  "                            if (myFullscreenBtn) myFullscreenBtn.remove();\n" +
  "                        }\n" +
  "                    }\n" +
  "                }\n" +
  "                //滑动长按判断\n" +
  "                if (endX === startX) {\n" +
  "                    //长按\n" +
  "                    //console.log(\"长按\");\n" +
  "                    if (rateTimer) {\n" +
  "                        //定时器也许已经执行，此时清除也没关系\n" +
  "                        clearTimeout(rateTimer);\n" +
  "                    }\n" +
  "                    if (longPress) {\n" +
  "                        //长按快进结束如果原本有控制器，则恢复\n" +
  "                        videoElement.controls = haveControls;\n" +
  "                        videoElement.playbackRate = 1;\n" +
  "                    }\n" +
  "                } else {\n" +
  "                    if (timeChange !== 0) {\n" +
  "                        //快进\n" +
  "                        videoElement.currentTime += timeChange;\n" +
  "                    }\n" +
  "                    //console.log(\"x轴移动\" + (endX - startX));\n" +
  "                    //console.log(\"y轴移动\" + (endY - startY));\n" +
  "                }\n" +
  "                target.removeEventListener(\"touchmove\", touchmoveHandler);\n" +
  "                if (notice) notice.remove();\n" +
  "            }\n" +
  "        });\n" +
  "    }\n" +
  "\n" +
  "\n" +
  "    //全屏后触发resize次数，如果有iframe，每个document可不是共用这个值\n" +
  "    let inTimes = 0;\n" +
  "    //利用window的resize事件监听全屏动作，监听document常用的fullscreenchange事件可能因为后代停止传播而捕获不到\n" +
  "    window.addEventListener(\"resize\", () => {\n" +
  "        //resize事件或先于全屏事件触发，此时判断是否全屏将出错，所以得设置延迟\n" +
  "        setTimeout(fullscreenHandler, 500);\n" +
  "    });\n" +
  "\n" +
  "    function fullscreenHandler() {\n" +
  "        //获取全屏元素，查找视频，判断视频长宽比来锁定方向\n" +
  "        let _fullscreenElement = document.fullscreenElement;\n" +
  "        if (_fullscreenElement) {\n" +
  "            //如果全屏元素是iframe，说明不是视频所在的document执行到这，记录也没用\n" +
  "            if (_fullscreenElement.tagName === \"IFRAME\") {\n" +
  "                return;\n" +
  "            }\n" +
  "            //inTimes==1可代表全屏\n" +
  "            inTimes++;\n" +
  "        } else if (inTimes > 0) {\n" +
  "            //此代码块可代表退出全屏\n" +
  "            inTimes = 0;\n" +
  "        } else {\n" +
  "            //退出全屏时多余的触发或者是其他与全屏无关的元素触发resize\n" +
  "            return;\n" +
  "        }\n" +
  "        if (inTimes !== 1) {\n" +
  "            return;\n" +
  "        }\n" +
  "        let videoElement;\n" +
  "        if (_fullscreenElement.tagName !== \"VIDEO\") {\n" +
  "            //最大的全屏元素不是视频本身，需要寻找视频元素\n" +
  "            let videoArray = _fullscreenElement.getElementsByTagName(\"video\");\n" +
  "            if (videoArray.length > 0) {\n" +
  "                videoElement = videoArray[0];\n" +
  "                if (videoArray.length > 1) {\n" +
  "                    console.log(\"全屏元素内找到不止一个视频。\");\n" +
  "                }\n" +
  "            }\n" +
  "        } else videoElement = _fullscreenElement;\n" +
  "        //也可能不是视频在全屏\n" +
  "        if (videoElement) {\n" +
  "            let changeHandler = function () {\n" +
  "                //高度小于宽度，需要转向，landscape会自动调用陀螺仪\n" +
  "                if (videoElement.videoHeight < videoElement.videoWidth) {\n" +
  "                    // 开启沙盒机制的iframe修改sandbox属性无效，需要顶层窗口调用方向锁定\n" +
  "                    sessionStorage.setItem(\"doLock\", JSON.stringify(true));\n" +
  "                }\n" +
  "            };\n" +
  "            //视频未加载，在加载后再判断需不需要转向\n" +
  "            if (videoElement.readyState < 1) {\n" +
  "                videoElement.addEventListener(\"loadedmetadata\", changeHandler, { once: true });\n" +
  "            } else {\n" +
  "                changeHandler();\n" +
  "            }\n" +
  "        }\n" +
  "    }\n" +
  "})();"

export default jsStr