
/*
 * CirclesUI.coffee
 * @author Mathieu Dutour - @MathieuDutour
 * @description Creates a Circles UI
 */

(function() {
  var lastTime, vendor, vendors, _fn, _i, _len,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

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
      scalarX: 1.0,
      scalarY: 1.0,
      frictionX: 0.1,
      frictionY: 0.1,
      precision: 1,
      classBig: "circle-big",
      classVisible: "circle-visible"
    };
    CirclesUI = function(element, options) {
      var data, key;
      this.element = element;
      this.circles = element.getElementsByClassName('circle-container');
      if (this.circles.length < 24) {
        throw new Error("Not enought circle to display a proper UI");
      } else {
        data = {
          relativeInput: this.data(this.element, 'relative-input'),
          clipRelativeInput: this.data(this.element, 'clipe-relative-input'),
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
        this.moved = false;
        this.bounds = null;
        this.ex = 0;
        this.ey = 0;
        this.ew = 0;
        this.eh = 0;
        this.portrait = null;
        this.ww = 0;
        this.wh = 0;
        this.circleDiameter = 0;
        this.numberOfCol = 0;
        this.numberOfRow = 0;
        this.miny = 0;
        this.maxy = 0;
        this.minx = 0;
        this.maxx = 0;
        this.cy = 0;
        this.cx = 0;
        this.ry = this.maxy - this.miny;
        this.rx = this.maxx - this.minx;
        this.fix = 0;
        this.fiy = 0;
        this.ix = 0;
        this.iy = 0;
        this.mx = 0;
        this.my = 0;
        this.vx = 0;
        this.vy = 0;
        this.vendorPrefix = (function() {
          var dom, pre, styles;
          styles = window.getComputedStyle(document.documentElement, "");
          pre = (Array.prototype.slice.call(styles).join("").match(/-(moz|webkit|ms)-/) || (styles.OLink === "" && ["", "o"]))[1];
          dom = "WebKit|Moz|MS|O".match(new RegExp("(" + pre + ")", "i"))[1];
          return {
            dom: dom,
            lowercase: pre,
            css: "-" + pre + "-",
            js: pre[0].toUpperCase() + pre.substr(1)
          };
        })();
        this.transform2DSupport = true;
        this.transform3DSupport = (function(transform) {
          var el, has3d;
          el = document.createElement("p");
          has3d = void 0;
          document.body.insertBefore(el, null);
          if (typeof el.style[transform] !== 'undefined') {
            el.style[transform] = "translate3d(1px,1px,1px)";
            has3d = window.getComputedStyle(el).getPropertyValue(transform);
          }
          document.body.removeChild(el);
          return typeof has3d !== 'undefined' && has3d.length > 0 && has3d !== "none";
        })(this.vendorPrefix.css + 'transform');
        this.setPositionAndScale = this.transform3DSupport ? function(element, x, y, s) {
          x = x.toFixed(this.precision) + 'px';
          y = y.toFixed(this.precision) + 'px';
          return this.css(element, this.vendorPrefix.js + 'Transform', 'translate3d(' + x + ',' + y + ',0)');
        } : this.transform2DSupport ? function(element, x, y, s) {
          x = x.toFixed(this.precision) + 'px';
          y = y.toFixed(this.precision) + 'px';
          return this.css(element, this.vendorPrefix.js + 'Transform', 'translate(' + x + ',' + y + ')');
        } : function(element, x, y, s) {
          x = x.toFixed(this.precision) + 'px';
          y = y.toFixed(this.precision) + 'px';
          element.style.left = x;
          return element.style.top = y;
        };
        this.onAnimationFrame = !isNaN(parseFloat(this.limitX)) && !isNaN(parseFloat(this.limitY)) ? function(now) {
          this.mx = this.clamp(this.ix * this.ew * this.scalarX, -this.limitX, this.limitX);
          this.my = this.clamp(this.iy * this.eh * this.scalarY, -this.limitY, this.limitY);
          this.vx += (this.mx - this.vx) * this.frictionX;
          this.vy += (this.my - this.vy) * this.frictionY;
          this.moveCircles(this.vx, this.vy);
          return this.raf = requestAnimationFrame(this.onAnimationFrame);
        } : !isNaN(parseFloat(this.limitX)) ? function(now) {
          this.mx = this.clamp(this.ix * this.ew * this.scalarX, -this.limitX, this.limitX);
          this.my = this.iy * this.eh * this.scalarY;
          this.vx += (this.mx - this.vx) * this.frictionX;
          this.vy += (this.my - this.vy) * this.frictionY;
          this.moveCircles(this.vx, this.vy);
          return this.raf = requestAnimationFrame(this.onAnimationFrame);
        } : !isNaN(parseFloat(this.limitY)) ? function(now) {
          this.mx = this.ix * this.ew * this.scalarX;
          this.my = this.clamp(this.iy * this.eh * this.scalarY, -this.limitY, this.limitY);
          this.vx += (this.mx - this.vx) * this.frictionX;
          this.vy += (this.my - this.vy) * this.frictionY;
          this.moveCircles(this.vx, this.vy);
          return this.raf = requestAnimationFrame(this.onAnimationFrame);
        } : function(now) {
          this.mx = this.ix * this.ew * this.scalarX;
          this.my = this.iy * this.eh * this.scalarY;
          this.vx += (this.mx - this.vx) * this.frictionX;
          this.vy += (this.my - this.vy) * this.frictionY;
          this.moveCircles(this.vx, this.vy);
          return this.raf = requestAnimationFrame(this.onAnimationFrame);
        };
        this.onMouseDown = this.relativeInput && this.clipRelativeInput ? function(event) {
          var clientX, clientY, _ref;
          event.preventDefault();
          if (!this.enabled) {
            if ((event.changedTouches != null) && event.changedTouches.length > 0) {
              this.activeTouch = event.changedTouches[0].identifier;
            }
            _ref = this.getCoordinatesFromEvent(event), clientX = _ref.clientX, clientY = _ref.clientY;
            clientX = this.clamp(clientX, this.ex, this.ex + this.ew);
            clientY = this.clamp(clientY, this.ey, this.ey + this.eh);
            this.fix = clientX;
            this.fiy = clientY;
            return this.enable();
          }
        } : function(event) {
          var clientX, clientY, _ref;
          event.preventDefault();
          if (!this.enabled) {
            if ((event.changedTouches != null) && event.changedTouches.length > 0) {
              this.activeTouch = event.changedTouches[0].identifier;
            }
            _ref = this.getCoordinatesFromEvent(event), clientX = _ref.clientX, clientY = _ref.clientY;
            this.fix = clientX;
            this.fiy = clientY;
            return this.enable();
          }
        };
        this.onMouseMove = this.relativeInput && this.clipRelativeInput ? function(event) {
          var clientX, clientY, _ref;
          event.preventDefault();
          if (!this.moved) {
            addClass(this.element, 'moved');
            this.moved = true;
          }
          _ref = this.getCoordinatesFromEvent(event), clientX = _ref.clientX, clientY = _ref.clientY;
          clientX = this.clamp(clientX, this.ex, this.ex + this.ew);
          clientY = this.clamp(clientY, this.ey, this.ey + this.eh);
          this.ix = (clientX - this.ex - this.fix) / this.ew;
          this.iy = (clientY - this.ey - this.fiy) / this.eh;
          this.fix = clientX;
          return this.fiy = clientY;
        } : this.relativeInput ? function(event) {
          var clientX, clientY, _ref;
          event.preventDefault();
          if (!this.moved) {
            addClass(this.element, 'moved');
            this.moved = true;
          }
          _ref = this.getCoordinatesFromEvent(event), clientX = _ref.clientX, clientY = _ref.clientY;
          this.ix = (clientX - this.ex - this.fix) / this.ew;
          this.iy = (clientY - this.ey - this.fiy) / this.eh;
          this.fix = clientX;
          return this.fiy = clientY;
        } : function(event) {
          var clientX, clientY, _ref;
          event.preventDefault();
          if (!this.moved) {
            addClass(this.element, 'moved');
            this.moved = true;
          }
          _ref = this.getCoordinatesFromEvent(event), clientX = _ref.clientX, clientY = _ref.clientY;
          this.ix = (clientX - this.fix) / this.ww;
          this.iy = (clientY - this.fiy) / this.wh;
          this.fix = clientX;
          return this.fiy = clientY;
        };
        this.onMouseDown = this.onMouseDown.bind(this);
        this.onMouseMove = this.onMouseMove.bind(this);
        this.onMouseUp = this.onMouseUp.bind(this);
        this.onAnimationFrame = this.onAnimationFrame.bind(this);
        this.onWindowResize = this.onWindowResize.bind(this);
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
      var ci, circle, cj, i, j, self, _fn, _i, _len, _ref;
      this.circles = this.element.getElementsByClassName('circle-container');
      this.numberOfCol = Math.ceil(Math.sqrt(2 * this.circles.length) / 2);
      if (this.numberOfCol < 4) {
        throw new Error("Need more element");
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
        if (j % self.numberOfCol === 0) {
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
      this.numberOfRow = this.circles[this.circles.length - 1].i + 1;
      ci = Math.floor(this.numberOfRow / 2) - 1;
      cj = Math.floor(this.numberOfCol / 2) - 2;
      this.layoutCircles(ci, cj);
      this.cx = parseFloat(this.circles[cj + this.numberOfCol * ci].x);
      return this.cy = parseFloat(this.circles[cj + this.numberOfCol * ci].y);
    };
    CirclesUI.prototype.layoutCircles = function(ci, cj) {
      var circle, self, _fn, _i, _len, _ref;
      self = this;
      _ref = this.circles;
      _fn = function(circle) {
        var offset;
        circle.y = 14 + (circle.i - ci) * 5;
        if ((circle.i - ci) % 2 === 1 || (circle.i - ci) % 2 === -1) {
          offset = 5;
        } else {
          offset = -2;
        }
        circle.x = offset + (circle.j - cj) * 14;
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
      this.ry = this.maxy - this.miny;
      this.minx = Math.min(parseFloat(Math.min(this.circles[0].x, this.circles[this.numberOfCol].x)) - parseFloat(this.circleDiameter) / 2, -parseFloat(this.circleDiameter) / 2);
      this.maxx = Math.max(Math.max(this.circles[this.circles.length - 1].x, this.circles[this.circles.length - 1 - this.numberOfCol].x) + parseFloat(this.circleDiameter), this.ew + parseFloat(this.circleDiameter) / 2);
      return this.rx = this.maxx - this.minx;
    };
    CirclesUI.prototype.appeared = function() {
      var addCSSRule, css, keyframes, s, self;
      addClass(this.element, "appeared");
      removeClass(this.element, "moved");
      this.moved = false;
      css = "" + this.vendorPrefix.css + "animation : appear 1s; " + this.vendorPrefix.css + "animation-delay: -400ms;";
      keyframes = "0% { " + this.vendorPrefix.css + "transform:translate3d(" + ((this.ew - this.circleDiameter) / 2) + "px, " + ((this.eh - this.circleDiameter) / 2) + "px, 0); opacity: 0; } 40% { opacity: 0; }";
      addCSSRule = function(sheet, selector, rules, index) {
        if ("insertRule" in sheet) {
          return sheet.insertRule(selector + "{" + rules + "}", index);
        } else {
          if ("addRule" in sheet) {
            return sheet.addRule(selector, rules, index);
          }
        }
      };
      if (document.styleSheets && document.styleSheets.length) {
        addCSSRule(document.styleSheets[0], "@" + this.vendorPrefix.css + "keyframes appear", keyframes, 0);
        addCSSRule(document.styleSheets[0], '#circlesUI.appeared > .circle-container.circle-visible', css, 0);
      } else {
        s = document.createElement('style');
        s.innerHTML = ("@" + this.vendorPrefix.css + "keyframes appear {") + keyframes + '} #circlesUI.appeared > .circle-container.circle-visible {' + css;
        document.getElementsByTagName('head')[0].appendChild(s);
      }
      self = this;
      return setTimeout((function() {
        return removeClass(self.element, "appeared");
      }), 1000);
    };
    CirclesUI.prototype.updateDimensions = function() {
      this.ww = window.innerWidth;
      this.wh = window.innerHeight;
      this.updateBounds();
      this.portrait = this.eh > this.ew;
      if (this.portrait) {
        this.circleDiameter = (6 / 34 * this.ew).toFixed(this.precision);
      } else {
        this.circleDiameter = (6 / 34 * this.eh).toFixed(this.precision);
      }
      return this.updateCircles();
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
            circle.x += self.rx * (1 + Math.floor((self.minx - circle.x) / self.rx));
          } else if (circle.x > self.maxx) {
            circle.x -= self.rx * (1 + Math.floor((circle.x - self.maxx) / self.rx));
          }
          if (circle.y < self.miny) {
            circle.y += self.ry * (1 + Math.floor((self.miny - circle.y) / self.ry));
          } else if (circle.y > self.maxy) {
            circle.y -= self.ry * (1 + Math.floor((circle.y - self.maxy) / self.ry));
          }
          return self.setCirclePosition(circle);
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
        return window.removeEventListener('touchmove', this.onMouseMove);
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
      if (circle.x > this.circleDiameter * 1 / 2 && circle.x < this.ew - this.circleDiameter * 3 / 2 && circle.y > this.circleDiameter * 1 / 3 && circle.y < this.eh - this.circleDiameter * 3 / 2) {
        addClass(circle, this.classBig);
      } else if (hasClass(circle, this.classBig)) {
        removeClass(circle, this.classBig);
      }
      if (circle.x > -this.circleDiameter && circle.x < this.ew + this.circleDiameter && circle.y > -this.circleDiameter && circle.y < this.eh + this.circleDiameter) {
        addClass(circle, this.classVisible);
      } else if (hasClass(circle, this.classVisible)) {
        removeClass(circle, this.classVisible);
      }
      return this.setPositionAndScale(circle, circle.x, circle.y, 1);
    };
    CirclesUI.prototype.onWindowResize = function(event) {
      return this.updateDimensions();
    };
    CirclesUI.prototype.getCoordinatesFromEvent = function(event) {
      if ((event.touches != null) && (event.touches.length != null) && event.touches.length > 0) {
        this.getCoordinatesFromEvent = function(event) {
          var find, self, touch;
          find = function(arr, f) {
            var e, _i, _len;
            for (_i = 0, _len = arr.length; _i < _len; _i++) {
              e = arr[_i];
              if (f(e)) {
                return e;
              }
            }
          };
          self = this;
          touch = find(event.touches, function(touch) {
            return touch.identifier === self.activeTouch;
          });
          return {
            clientX: touch.clientX,
            clientY: touch.clientY
          };
        };
      } else {
        this.getCoordinatesFromEvent = function(event) {
          return {
            clientX: event.clientX,
            clientY: event.clientY
          };
        };
      }
      return this.getCoordinatesFromEvent(event);
    };
    CirclesUI.prototype.onMouseUp = function(event) {
      var i;
      this.ix = 0;
      this.iy = 0;
      this.activeTouch = null;
      this.disable();
      i = 0;
      while (Math.abs(this.vx) > 0 && Math.abs(this.vx) > 0 && i < 50) {
        this.raf = requestAnimationFrame(this.onAnimationFrame);
        i++;
      }
      return cancelAnimationFrame(this.raf);
    };
    return window[NAME] = CirclesUI;
  })(window, document);


  /*
   * Request Animation Frame Polyfill.
   * @author Tino Zijdel
   * @author Paul Irish
   * @see https://gist.github.com/paulirish/1579671
   */

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

//# sourceMappingURL=script.js.map
