
/*
 * CirclesUI.coffee
 * @author Mathieu Dutour - @MathieuDutour
 * @description Creates a CirclesUI effect between an array of layers,
 *              driving the motion from the gyroscope output of a smartdevice.
 *              If no gyroscope is available, the cursor position is used.
 */

(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  (function(window, document) {
    var CirclesUI, DEFAULTS, NAME, addClass, classReg, hasClass, removeClass;
    classReg = function(className) {
      return new RegExp("(^|\\s+)" + className + "(\\s+|$)");
    };
    if (__indexOf.call(document.documentElement, 'classList') >= 0) {
      hasClass = function(elem, c) {
        return elem.classList.contains(c);
      };
      addClass = function(elem, c) {
        return elem.classList.add(c);
      };
      removeClass = function(elem, c) {
        return elem.classList.remove(c);
      };
    } else {
      hasClass = function(elem, c) {
        return classReg(c).test(elem.className);
      };
      addClass = function(elem, c) {
        if (!hasClass(elem, c)) {
          return elem.className = elem.className + ' ' + c;
        }
      };
      removeClass = function(elem, c) {
        return elem.className = elem.className.replace(classReg(c), ' ');
      };
    }
    NAME = 'CirclesUI';
    DEFAULTS = {
      relativeInput: false,
      clipRelativeInput: false,
      invertX: false,
      invertY: false,
      limitX: false,
      limitY: false,
      scalarX: 200.0,
      scalarY: 200.0,
      frictionX: 0.1,
      frictionY: 0.1,
      precision: 1,
      classBig: "circle-big",
      classVisible: "circle-visible"
    };
    CirclesUI = function(element, options) {
      var data, getVendorCSSPrefix, getVendorPrefix, key;
      this.element = element;
      this.circles = element.getElementsByClassName('circle-container');
      if (this.circles.length < 24) {
        return console.log("Not enought circle to display a proper UI");
      } else {
        data = {
          invertX: this.data(this.element, 'invert-x'),
          invertY: this.data(this.element, 'invert-y'),
          limitX: this.data(this.element, 'limit-x'),
          limitY: this.data(this.element, 'limit-y'),
          scalarX: this.data(this.element, 'scalar-x'),
          scalarY: this.data(this.element, 'scalar-y'),
          frictionX: this.data(this.element, 'friction-x'),
          frictionY: this.data(this.element, 'friction-y'),
          precision: this.data(this.element, 'precision'),
          classBig: this.data(this.element, 'class-big'),
          classVisible: this.data(this.element, 'class-visible')
        };
        for (key in data) {
          if (data[key] === null) {
            delete data[key];
          }
        }
        this.extend(this, DEFAULTS, options, data);
        this.enabled = false;
        this.raf = null;
        this.bounds = null;
        this.ex = 0;
        this.ey = 0;
        this.ew = 0;
        this.eh = 0;
        this.fix = 0;
        this.fiy = 0;
        this.ix = 0;
        this.iy = 0;
        this.mx = 0;
        this.my = 0;
        this.vx = 0;
        this.vy = 0;
        this.onMouseDown = this.onMouseDown.bind(this);
        this.onMouseMove = this.onMouseMove.bind(this);
        this.onMouseUp = this.onMouseUp.bind(this);
        this.onAnimationFrame = this.onAnimationFrame.bind(this);
        this.onWindowResize = this.onWindowResize.bind(this);
        getVendorPrefix = function(arrayOfPrefixes) {
          var i, result;
          result = null;
          i = 0;
          while (i < arrayOfPrefixes.length) {
            if (typeof element.style[arrayOfPrefixes[i]] !== "undefined") {
              result = arrayOfPrefixes[i];
              break;
            }
            ++i;
          }
          return result;
        };
        getVendorCSSPrefix = function(arrayOfPrefixes) {
          var i, result;
          result = null;
          i = 0;
          while (i < arrayOfPrefixes.length) {
            if (typeof element.style[arrayOfPrefixes[i][0]] !== "undefined") {
              result = arrayOfPrefixes[i][1];
              break;
            }
            ++i;
          }
          return result;
        };
        this.vendorPrefix = {
          css: getVendorCSSPrefix([["transform", ""], ["msTransform", "-ms-"], ["MozTransform", "-moz-"], ["WebkitTransform", "-webkit-"], ["OTransform", "-o-"]]),
          transform: getVendorPrefix(["transform", "msTransform", "MozTransform", "WebkitTransform", "OTransform"])
        };
        return this.initialise();
      }
    };
    CirclesUI.prototype.extend = function() {
      var master, object, _i, _len, _results;
      if (arguments.length > 1) {
        master = arguments[0];
        _results = [];
        for (_i = 0, _len = arguments.length; _i < _len; _i++) {
          object = arguments[_i];
          _results.push((function(object) {
            var key, _results1;
            _results1 = [];
            for (key in object) {
              _results1.push(master[key] = object[key]);
            }
            return _results1;
          })(object));
        }
        return _results;
      }
    };
    CirclesUI.prototype.data = function(element, name) {
      return this.deserialize(element.getAttribute('data-' + name));
    };
    CirclesUI.prototype.deserialize = function(value) {
      if (value === "true") {
        return true;
      } else if (value === "false") {
        return false;
      } else if (value === "null") {
        return null;
      } else if (!isNaN(parseFloat(value)) && isFinite(value)) {
        return parseFloat(value);
      } else {
        return value;
      }
    };
    CirclesUI.prototype.transfSupport = function(value) {
      var cssProperty, element, featureSupport, i, jsProperty, propertySupport, propertyValue;
      element = document.createElement('div');
      propertySupport = false;
      propertyValue = null;
      featureSupport = false;
      cssProperty = null;
      jsProperty = null;
      i = 0;
      propertySupport = this.vendorPrefix.transform != null;
      switch (value) {
        case '2D':
          featureSupport = propertySupport;
          break;
        case '3D':
          (function() {
            var body, documentElement, documentOverflow, isCreatedBody;
            if (propertySupport) {
              body = document.body || document.createElement('body');
              documentElement = document.documentElement;
              documentOverflow = documentElement.style.overflow;
              isCreatedBody = false;
              if (!document.body) {
                isCreatedBody = true;
                documentElement.style.overflow = 'hidden';
                documentElement.appendChild(body);
                body.style.overflow = 'hidden';
                body.style.background = '';
              }
              body.appendChild(element);
              element.style[this.vendorPrefix.transform] = 'translate3d(1px,1px,1px)';
              propertyValue = window.getComputedStyle(element).getPropertyValue(cssProperty);
              featureSupport = (propertyValue != null) && propertyValue.length > 0 && propertyValue !== "none";
              documentElement.style.overflow = documentOverflow;
              body.removeChild(element);
              if (isCreatedBody) {
                body.removeAttribute('style');
                return body.parentNode.removeChild(body);
              }
            }
          })();
      }
      return featureSupport;
    };
    CirclesUI.prototype.ww = null;
    CirclesUI.prototype.wh = null;
    CirclesUI.prototype.wrx = null;
    CirclesUI.prototype.wry = null;
    CirclesUI.prototype.portrait = null;
    CirclesUI.prototype.transform2DSupport = true;
    CirclesUI.prototype.transform3DSupport = true;
    CirclesUI.prototype.initialise = function() {
      var style;
      if (this.transform3DSupport) {
        this.accelerate(this.element);
      }
      style = window.getComputedStyle(this.element);
      if (style.getPropertyValue('position') === 'static') {
        this.element.style.position = 'relative';
      }
      window.addEventListener('mousedown', this.onMouseDown);
      window.addEventListener('mouseup', this.onMouseUp);
      window.addEventListener('touchstart', this.onMouseDown);
      window.addEventListener('touchend', this.onMouseUp);
      window.addEventListener('resize', this.onWindowResize);
      this.updateDimensions();
      return this.updateCircles();
    };
    CirclesUI.prototype.updateCircles = function() {
      var ci, circle, circlesMatrix, cj, i, j, numberOfCol, self, _fn, _i, _len, _ref;
      this.circles = this.element.getElementsByClassName('circle-container');
      circlesMatrix = [];
      numberOfCol = Math.ceil(Math.sqrt(2 * this.circles.length) / 2);
      if (numberOfCol < 4) {
        console.log("need more for now");
      }
      j = 0;
      i = -1;
      self = this;
      _ref = this.circles;
      _fn = function(circle) {
        if (self.transform3DSupport) {
          self.accelerate(circle);
        }
        circle.style.width = self.circleDiameter + "px";
        circle.style.height = self.circleDiameter + "px";
        if (j % numberOfCol === 0) {
          i++;
          j = 0;
        }
        circle.i = i;
        circle.j = j;
        return j++;
      };
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        circle = _ref[_i];
        _fn(circle);
      }
      this.numberOfCol = numberOfCol;
      this.numberOfRow = this.circles[this.circles.length - 1].i + 1;
      ci = Math.floor(this.numberOfRow / 2) - 1;
      cj = Math.floor(this.numberOfCol / 2) - 2;
      return this.layoutCircles(ci, cj);
    };
    CirclesUI.prototype.layoutCircles = function(ci, cj) {
      var circle, self, _fn, _i, _len, _ref;
      self = this;
      _ref = this.circles;
      _fn = function(circle) {
        var offset;
        circle.y = 14 + (circle.i - ci) * 5;
        if ((circle.i - ci) % 2 === 1 || (circle.i - ci) % 2 === -1) {
          offset = -7;
        } else {
          offset = -14;
        }
        circle.x = offset + 12 + (circle.j - cj) * 14;
        circle.y = circle.y / 34 * (self.portrait ? self.ew : self.eh);
        circle.x = circle.x / 44 * (self.portrait ? self.eh : self.ew);
        return self.setCirclePosition(circle);
      };
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        circle = _ref[_i];
        _fn(circle);
      }
      this.appeared();
      this.miny = Math.min(parseFloat(this.circles[0].y) - parseFloat(this.circleDiameter) / 2, -parseFloat(this.circleDiameter) / 2);
      this.maxy = Math.max(parseFloat(this.circles[this.circles.length - 1].y) + parseFloat(this.circleDiameter) / 2, this.eh + parseFloat(this.circleDiameter) / 2);
      this.cy = parseFloat(this.circles[cj + this.numberOfCol * ci].y);
      this.ry = this.maxy - this.miny;
      this.minx = Math.min(parseFloat(Math.min(this.circles[0].x, this.circles[this.numberOfCol].x)) - parseFloat(this.circleDiameter) / 2, -parseFloat(this.circleDiameter) / 2);
      this.maxx = Math.max(Math.max(this.circles[this.circles.length - 1].x, this.circles[this.circles.length - 1 - this.numberOfCol].x) + parseFloat(this.circleDiameter), this.ew + parseFloat(this.circleDiameter) / 2);
      this.cx = parseFloat(this.circles[cj + this.numberOfCol * ci].x);
      return this.rx = this.maxx - this.minx;
    };
    CirclesUI.prototype.appeared = function() {
      var css, keyframes, s, self;
      addClass(this.element, "appeared");
      self = this;
      setTimeout((function() {
        return removeClass(self.element, "appeared");
      }), 1000);
      css = "#circlesUI.appeared > .circle-container.circle-visible { " + this.vendorPrefix.css + "animation : appear 1s; " + this.vendorPrefix.css + "animation-delay: -400ms; }";
      keyframes = "@" + this.vendorPrefix.css + "keyframes appear { 0% { " + this.vendorPrefix.css + "transform:translate3d(" + ((this.ew - this.circleDiameter) / 2) + "px, " + ((this.eh - this.circleDiameter) / 2) + "px, 0); opacity: 0; } 40% { opacity: 0; } }";
      if (document.styleSheets && document.styleSheets.length) {
        document.styleSheets[0].insertRule(keyframes, 0);
        return document.styleSheets[0].insertRule(css, 0);
      } else {
        s = document.createElement('style');
        s.innerHTML = keyframes + css;
        return document.getElementsByTagName('head')[0].appendChild(s);
      }
    };
    CirclesUI.prototype.updateDimensions = function() {
      var portrait;
      this.ww = window.innerWidth;
      this.wh = window.innerHeight;
      this.updateBounds();
      portrait = this.eh > this.ew;
      if (portrait) {
        this.circleDiameter = (6 / 34 * this.ew).toFixed(this.precision);
      } else {
        this.circleDiameter = (6 / 34 * this.eh).toFixed(this.precision);
      }
      this.updateCircles();
      return this.portrait = portrait;
    };
    CirclesUI.prototype.updateBounds = function() {
      this.bounds = this.element.getBoundingClientRect();
      this.ex = this.bounds.left;
      this.ey = this.bounds.top;
      this.ew = this.bounds.width;
      return this.eh = this.bounds.height;
    };
    CirclesUI.prototype.findCenterCircle = function() {
      var center, circle, distance, self, _fn, _i, _len, _ref;
      self = this;
      distance = this.rx * this.rx + this.ry * this.ry;
      center = null;
      _ref = this.circles;
      _fn = function(circle) {
        var dist;
        dist = (circle.x - self.cx) * (circle.x - self.cx) + (circle.y - self.cy) * (circle.y - self.cy);
        if (dist < distance) {
          distance = dist;
          return center = circle;
        }
      };
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        circle = _ref[_i];
        _fn(circle);
      }
      return center;
    };
    CirclesUI.prototype.moveCircles = function(dx, dy) {
      var circle, self, _i, _len, _ref, _results;
      self = this;
      _ref = this.circles;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        circle = _ref[_i];
        _results.push((function(circle) {
          circle.x += dx;
          circle.y += dy;
          if (circle.x < self.minx) {
            addClass(circle, "hideMovement");
            circle.x += self.rx * (1 + Math.floor((self.minx - circle.x) / self.rx));
          } else if (circle.x > self.maxx) {
            addClass(circle, "hideMovement");
            circle.x -= self.rx * (1 + Math.floor((circle.x - self.maxx) / self.rx));
          }
          if (circle.y < self.miny) {
            addClass(circle, "hideMovement");
            circle.y += self.ry * (1 + Math.floor((self.miny - circle.y) / self.ry));
          } else if (circle.y > self.maxy) {
            addClass(circle, "hideMovement");
            circle.y -= self.ry * (1 + Math.floor((circle.y - self.maxy) / self.ry));
          }
          self.setCirclePosition(circle);
          return removeClass(circle, "hideMovement");
        })(circle));
      }
      return _results;
    };
    CirclesUI.prototype.enable = function() {
      if (!this.enabled) {
        this.enabled = true;
        window.addEventListener('mousemove', this.onMouseMove);
        window.addEventListener('touchmove', this.onMouseMove);
        return this.raf = requestAnimationFrame(this.onAnimationFrame);
      }
    };
    CirclesUI.prototype.disable = function() {
      if (this.enabled) {
        this.enabled = false;
        window.removeEventListener('mousemove', this.onMouseMove);
        window.removeEventListener('touchmove', this.onMouseMove);
        return cancelAnimationFrame(this.raf);
      }
    };
    CirclesUI.prototype.calibrate = function(x, y) {
      this.calibrateX = x != null ? x : this.calibrateX;
      return this.calibrateY = y != null ? y : this.calibrateY;
    };
    CirclesUI.prototype.invert = function(x, y) {
      this.invertX = x != null ? x : this.invertX;
      return this.invertY = y != null ? y : this.invertY;
    };
    CirclesUI.prototype.friction = function(x, y) {
      this.frictionX = x != null ? x : this.frictionX;
      return this.frictionY = y != null ? y : this.frictionY;
    };
    CirclesUI.prototype.scalar = function(x, y) {
      this.scalarX = x != null ? x : this.scalarX;
      return this.scalarY = y != null ? y : this.scalarY;
    };
    CirclesUI.prototype.limit = function(x, y) {
      this.limitX = x != null ? x : this.limitX;
      return this.limitY = y != null ? y : this.limitY;
    };
    CirclesUI.prototype.clamp = function(value, min, max) {
      value = Math.max(value, min);
      return Math.min(value, max);
    };
    CirclesUI.prototype.css = function(element, property, value) {
      return element.style[property] = value;
    };
    CirclesUI.prototype.accelerate = function(element) {
      return this.css(element, this.vendorPrefix.transform, 'translate3d(0,0,0)');
    };
    CirclesUI.prototype.setCirclePosition = function(circle) {
      if (circle.x > this.circleDiameter * 1 / 2 && circle.x < this.ww - this.circleDiameter * 3 / 2 && circle.y > this.circleDiameter * 1 / 3 && circle.y < this.wh - this.circleDiameter * 3 / 2) {
        addClass(circle, this.classBig);
      } else if (hasClass(circle, this.classBig)) {
        removeClass(circle, this.classBig);
      }
      if (circle.x > -this.circleDiameter && circle.x < this.ww + this.circleDiameter && circle.y > -this.circleDiameter && circle.y < this.wh + this.circleDiameter) {
        addClass(circle, this.classVisible);
      } else if (hasClass(circle, this.classVisible)) {
        removeClass(circle, this.classVisible);
      }
      return this.setPositionAndScale(circle, circle.x, circle.y, 1);
    };
    CirclesUI.prototype.setPositionAndScale = function(element, x, y, s) {
      x = x.toFixed(this.precision);
      y = y.toFixed(this.precision);
      x += 'px';
      y += 'px';
      if (this.transform3DSupport) {
        return this.css(element, this.vendorPrefix.transform, 'translate3d(' + x + ',' + y + ',0)');
      } else if (this.transform2DSupport) {
        return this.css(element, this.vendorPrefix.transform, 'translate(' + x + ',' + y + ')');
      } else {
        element.style.left = x;
        return element.style.top = y;
      }
    };
    CirclesUI.prototype.onWindowResize = function(event) {
      return this.updateDimensions();
    };
    CirclesUI.prototype.onAnimationFrame = function() {
      this.mx = this.ix;
      this.my = this.iy;
      this.mx *= this.ew * (this.scalarX / 100);
      this.my *= this.eh * (this.scalarY / 100);
      if (!isNaN(parseFloat(this.limitX))) {
        this.mx = this.clamp(this.mx, -this.limitX, this.limitX);
      }
      if (!isNaN(parseFloat(this.limitY))) {
        this.my = this.clamp(this.my, -this.limitY, this.limitY);
      }
      this.vx += (this.mx - this.vx) * this.frictionX;
      this.vy += (this.my - this.vy) * this.frictionY;
      if (Math.abs(this.vx) < 1) {
        this.vx = 0;
      }
      if (Math.abs(this.vy) < 1) {
        this.vy = 0;
      }
      this.moveCircles(this.vx, this.vy);
      return this.raf = requestAnimationFrame(this.onAnimationFrame);
    };
    CirclesUI.prototype.getCoordinatesFromEvent = function(event) {
      var self, touch, _i, _len, _ref, _results;
      self = this;
      if ((event.touches != null) && (event.touches.length != null) && event.touches.length > 0) {
        _ref = event.touches;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          touch = _ref[_i];
          _results.push((function(touch) {
            console.log(touch.identifier);
            console.log(self.activeTouch);
            if (touch.identifier === self.activeTouch) {
              return {
                clientX: touch.clientX,
                clientY: touch.clientY
              };
            }
          })(touch));
        }
        return _results;
      } else {
        return {
          clientX: event.clientX,
          clientY: event.clientY
        };
      }
    };
    CirclesUI.prototype.onMouseDown = function(event) {
      var clientX, clientY, _ref;
      event.preventDefault();
      if (!this.enabled) {
        if ((event.changedTouches != null) && event.changedTouches.length > 0) {
          this.activeTouch = event.changedTouches[0].identifier;
        }
        _ref = this.getCoordinatesFromEvent(event), clientX = _ref.clientX, clientY = _ref.clientY;
        if (this.relativeInput && this.clipRelativeInput) {
          clientX = this.clamp(clientX, this.ex, this.ex + this.ew);
          clientY = this.clamp(clientY, this.ey, this.ey + this.eh);
        }
        this.fix = clientX;
        this.fiy = clientY;
        return this.enable();
      }
    };
    CirclesUI.prototype.onMouseUp = function(event) {
      var i;
      this.ix = 0;
      this.iy = 0;
      this.activeTouch = null;
      i = 0;
      while (Math.abs(this.vx) > 0 && Math.abs(this.vx) > 0 && i < 50) {
        this.raf = requestAnimationFrame(this.onAnimationFrame);
        i++;
      }
      return this.disable();

      /*addClass(@element, "animating")
      center = @findCenterCircle()
      dx = center.x - @cx
      dy = center.y - @cy
      @moveCircles(dx, dy)
      self = this
      setTimeout ( ->
        removeClass self.element, "animating"
      ), 300
       */
    };
    CirclesUI.prototype.onMouseMove = function(event) {
      var clientX, clientY, _ref;
      event.preventDefault();
      if (!hasClass(this.element, 'moved')) {
        addClass(this.element, 'moved');
      }
      _ref = this.getCoordinatesFromEvent(event), clientX = _ref.clientX, clientY = _ref.clientY;
      if (this.relativeInput) {
        if (this.clipRelativeInput) {
          clientX = this.clamp(clientX, this.ex, this.ex + this.ew);
          clientY = this.clamp(clientY, this.ey, this.ey + this.eh);
        }
        this.ix = (clientX - this.ex - this.fix) / this.ew;
        this.iy = (clientY - this.ey - this.fiy) / this.eh;
      } else {
        this.ix = (clientX - this.fix) / this.ww;
        this.iy = (clientY - this.fiy) / this.wh;
      }
      console.log(this.ix);
      console.log(this.iy);
      this.fix = clientX;
      return this.fiy = clientY;
    };
    return window[NAME] = CirclesUI;
  })(window, document);

}).call(this);


/*
 * Request Animation Frame Polyfill.
 * @author Tino Zijdel
 * @author Paul Irish
 * @see https://gist.github.com/paulirish/1579671
 */

(function() {
  var lastTime, vendor, vendors, _fn, _i, _len;

  lastTime = 0;

  vendors = ['ms', 'moz', 'webkit', 'o'];

  _fn = function(vendor) {
    window.requestAnimationFrame = window[vendor + 'RequestAnimationFrame'];
    return window.cancelAnimationFrame = window[vendor + 'CancelAnimationFrame'] || window[vendor + 'CancelRequestAnimationFrame'];
  };
  for (_i = 0, _len = vendors.length; _i < _len; _i++) {
    vendor = vendors[_i];
    _fn(vendor);
  }

  if (!window.requestAnimationFrame) {
    window.requestAnimationFrame = function(callback, element) {
      var currTime, id, timeToCall;
      currTime = new Date().getTime();
      timeToCall = Math.max(0, 16 - (currTime - lastTime));
      id = window.setTimeout(function() {
        return callback(currTime + timeToCall);
      }, timeToCall);
      lastTime = currTime + timeToCall;
      return id;
    };
  }

  if (!window.cancelAnimationFrame) {
    window.cancelAnimationFrame = function(id) {
      return clearTimeout(id);
    };
  }

}).call(this);
