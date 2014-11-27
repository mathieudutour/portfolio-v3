(function() {
  var lastTime, vendor, vendors, _fn, _i, _len,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  (function(window, document) {
    var Age;
    Age = (function() {
      function Age(element, birthday, options) {
        this.element = element;
        this.number_of_millisecond_in_a_year = 31556926000;
        this.birthday = new Date(birthday).getTime();
        this.age = 0;
        this.fraction = 0;
        this.precision = 9;
        this.initialise();
      }

      Age.prototype.initialise = function() {
        var self;
        this.initDisplay();
        self = this;
        return setInterval((function() {
          return self.updateDisplay();
        }), 10);
      };

      Age.prototype.calculateAge = function() {
        this.age = Math.floor((new Date().getTime() - this.birthday) / this.number_of_millisecond_in_a_year);
        return this.birthday += this.age * this.number_of_millisecond_in_a_year;
      };

      Age.prototype.calculateFraction = function() {
        return this.fraction = (((new Date().getTime() - this.birthday) / this.number_of_millisecond_in_a_year).toFixed(this.precision) * 1000000000).toString().substring(0, this.precision);
      };

      Age.prototype.initDisplay = function() {
        this.ageDisplay = document.createElement("span");
        this.fractionDisplay = document.createElement("span");
        this.element.insertBefore(this.ageDisplay, null);
        this.element.insertBefore(this.fractionDisplay, null);
        this.calculateAge();
        this.ageDisplay.innerHTML = this.age;
        return this.updateDisplay();
      };

      Age.prototype.updateDisplay = function() {
        this.calculateFraction();
        return this.fractionDisplay.innerHTML = '.' + this.pad();
      };

      Age.prototype.pad = function() {
        if (this.fraction.length < this.precision) {
          this.fraction = "0" + this.fraction;
          return this.pad();
        } else {
          return this.fraction;
        }
      };

      return Age;

    })();
    return window.Age = Age;
  })(window, document);


  /*
   * CirclesUI.coffee
   * @author Mathieu Dutour - @MathieuDutour
   * @description Creates a Circles UI
   */

  (function(window, document) {
    var CirclesUI, DEFAULTS, NAME, addClass, classReg, classie, hasClass, removeClass;
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
    classie = {
      hasClass: hasClass,
      addClass: addClass,
      removeClass: removeClass
    };
    window.classie = classie;
    NAME = 'CirclesUI';
    DEFAULTS = {
      wrap: true,
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
    return CirclesUI = (function() {
      function CirclesUI(element, options) {
        var data, key, _ref;
        this.element = element;
        this.circles = element.getElementsByClassName('circle-container');
        if (this.circles.length < 24) {
          throw new Error("Not enought circle to display a proper UI");
        } else {
          data = {
            wrap: this.data(this.element, 'wrap'),
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
          this.started = false;
          this.dragging = false;
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
          _ref = (function(transform) {
            var el2d, el3d, has2d, has3d;
            el2d = document.createElement("p");
            el3d = document.createElement("p");
            has2d = void 0;
            has3d = void 0;
            document.body.insertBefore(el2d, null);
            if (typeof el2d.style[transform] !== 'undefined') {
              document.body.insertBefore(el3d, null);
              el2d.style[transform] = "translate(1px,1px)";
              has2d = window.getComputedStyle(el2d).getPropertyValue(transform);
              el3d.style[transform] = "translate3d(1px,1px,1px)";
              has3d = window.getComputedStyle(el3d).getPropertyValue(transform);
              document.body.removeChild(el3d);
            }
            document.body.removeChild(el2d);
            return [typeof has2d !== 'undefined' && has2d.length > 0 && has2d !== "none", typeof has3d !== 'undefined' && has3d.length > 0 && has3d !== "none"];
          })(this.vendorPrefix.css + 'transform'), this.transform2DSupport = _ref[0], this.transform3DSupport = _ref[1];
          this.setPositionAndScale = this.transform3DSupport ? function(element, x, y, s, updateS) {
            var circle;
            x = x.toFixed(this.precision) + 'px';
            y = y.toFixed(this.precision) + 'px';
            this.css(element, this.vendorPrefix.js + 'Transform', 'translate3d(' + x + ',' + y + ',0)');
            if (updateS) {
              circle = element.getElementsByClassName('circle');
              return this.css(circle[0], this.vendorPrefix.js + 'Transform', 'scale3d(' + s + ',' + s + ',1)');
            }
          } : this.transform2DSupport ? function(element, x, y, s) {
            var circle;
            x = x.toFixed(this.precision) + 'px';
            y = y.toFixed(this.precision) + 'px';
            this.css(element, this.vendorPrefix.js + 'Transform', 'translate(' + x + ',' + y + ')');
            if (updateS) {
              circle = element.getElementsByClassName('circle');
              return this.css(circle[0], this.vendorPrefix.js + 'Transform', 'scale(' + s + ',' + s + ')');
            }
          } : function(element, x, y, s) {
            var circle;
            x = x.toFixed(this.precision) + 'px';
            y = y.toFixed(this.precision) + 'px';
            element.style.left = x;
            element.style.top = y;
            if (updateS) {
              circle = element.getElementsByClassName('circle');
              s = s * 100 + '%';
              circle.style.width = s;
              return circle.style.height = s;
            }
          };
          this.moveCircles = this.wrap ? function(dx, dy) {
            var circle, self, _i, _len, _ref1, _results;
            self = this;
            _ref1 = this.circles;
            _results = [];
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              circle = _ref1[_i];
              _results.push((function(circle) {
                var _ref2, _ref3;
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
                if ((self.minx < (_ref2 = circle.x) && _ref2 < self.maxx) && (self.miny < (_ref3 = circle.y) && _ref3 < self.maxy)) {
                  return self.setCirclePosition(circle);
                }
              })(circle));
            }
            return _results;
          } : function(dx, dy) {
            var circle, self, _i, _len, _ref1, _results;
            self = this;
            _ref1 = this.circles;
            _results = [];
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              circle = _ref1[_i];
              _results.push((function(circle) {
                var _ref2, _ref3;
                circle.x += dx;
                circle.y += dy;
                if ((self.minx < (_ref2 = circle.x) && _ref2 < self.maxx) && (self.miny < (_ref3 = circle.y) && _ref3 < self.maxy)) {
                  return self.setCirclePosition(circle);
                }
              })(circle));
            }
            return _results;
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
            var clientX, clientY, _ref1;
            if (!this.dragging) {
              if ((event.changedTouches != null) && event.changedTouches.length > 0) {
                this.activeTouch = event.changedTouches[0].identifier;
              } else {
                event.preventDefault();
              }
              _ref1 = this.getCoordinatesFromEvent(event), clientX = _ref1.clientX, clientY = _ref1.clientY;
              clientX = this.clamp(clientX, this.ex, this.ex + this.ew);
              clientY = this.clamp(clientY, this.ey, this.ey + this.eh);
              this.fix = clientX;
              this.fiy = clientY;
              return this.enableDrag();
            }
          } : function(event) {
            var clientX, clientY, _ref1;
            if (!this.dragging) {
              if ((event.changedTouches != null) && event.changedTouches.length > 0) {
                this.activeTouch = event.changedTouches[0].identifier;
              } else {
                event.preventDefault();
              }
              _ref1 = this.getCoordinatesFromEvent(event), clientX = _ref1.clientX, clientY = _ref1.clientY;
              this.fix = clientX;
              this.fiy = clientY;
              return this.enableDrag();
            }
          };
          this.onMouseMove = this.relativeInput && this.clipRelativeInput ? function(event) {
            var clientX, clientY, _ref1;
            event.preventDefault();
            if (!this.moved) {
              addClass(this.element, 'moved');
              this.moved = true;
            }
            _ref1 = this.getCoordinatesFromEvent(event), clientX = _ref1.clientX, clientY = _ref1.clientY;
            clientX = this.clamp(clientX, this.ex, this.ex + this.ew);
            clientY = this.clamp(clientY, this.ey, this.ey + this.eh);
            this.ix = (clientX - this.ex - this.fix) / this.ew;
            this.iy = (clientY - this.ey - this.fiy) / this.eh;
            this.fix = clientX;
            return this.fiy = clientY;
          } : this.relativeInput ? function(event) {
            var clientX, clientY, _ref1;
            event.preventDefault();
            if (!this.moved) {
              addClass(this.element, 'moved');
              this.moved = true;
            }
            _ref1 = this.getCoordinatesFromEvent(event), clientX = _ref1.clientX, clientY = _ref1.clientY;
            this.ix = (clientX - this.ex - this.fix) / this.ew;
            this.iy = (clientY - this.ey - this.fiy) / this.eh;
            this.fix = clientX;
            return this.fiy = clientY;
          } : function(event) {
            var clientX, clientY, _ref1;
            event.preventDefault();
            if (!this.moved) {
              addClass(this.element, 'moved');
              this.moved = true;
            }
            _ref1 = this.getCoordinatesFromEvent(event), clientX = _ref1.clientX, clientY = _ref1.clientY;
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
          this.initialise();
        }
      }

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
        this.start();
        this.updateDimensions();
        return this.updateCircles();
      };

      CirclesUI.prototype.start = function() {
        if (!this.started) {
          this.started = true;
          window.addEventListener('mousedown', this.onMouseDown);
          window.addEventListener('mouseup', this.onMouseUp);
          window.addEventListener('touchstart', this.onMouseDown);
          window.addEventListener('touchend', this.onMouseUp);
          return window.addEventListener('resize', this.onWindowResize);
        }
      };

      CirclesUI.prototype.stop = function() {
        if (this.started) {
          this.started = false;
          cancelAnimationFrame(this.raf);
          window.removeEventListener('mousedown', this.onMouseDown);
          window.removeEventListener('mouseup', this.onMouseUp);
          window.removeEventListener('touchstart', this.onMouseDown);
          window.removeEventListener('touchend', this.onMouseUp);
          return window.removeEventListener('resize', this.onWindowResize);
        }
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
          return self.setCirclePosition(circle, true);
        };
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          circle = _ref[_i];
          _fn(circle);
        }
        this.appeared();
        this.miny = Math.min(parseFloat(this.circles[0].y) - parseFloat(this.circleDiameter) * 2 / 3, -parseFloat(this.circleDiameter) * 2 / 3);
        this.maxy = Math.max(parseFloat(this.circles[this.circles.length - 1].y) + parseFloat(this.circleDiameter) / 2, this.eh - parseFloat(this.circleDiameter) * 2 / 3);
        this.ry = this.maxy - this.miny;
        this.minx = Math.min(parseFloat(Math.min(this.circles[0].x, this.circles[this.numberOfCol].x)) - parseFloat(this.circleDiameter) * 2 / 3, -parseFloat(this.circleDiameter) * 2 / 3);
        this.maxx = Math.max(Math.max(this.circles[this.circles.length - 1].x, this.circles[this.circles.length - 1 - this.numberOfCol].x) + parseFloat(this.circleDiameter) * 2 / 3, this.ew - parseFloat(this.circleDiameter) * 2 / 3);
        return this.rx = this.maxx - this.minx;
      };

      CirclesUI.prototype.appeared = function() {
        var addCSSRule, css, keyframes, s, self;
        addClass(this.element, "appeared");
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

      CirclesUI.prototype.enableDrag = function() {
        if (!this.dragging) {
          this.dragging = true;
          window.addEventListener('mousemove', this.onMouseMove);
          window.addEventListener('touchmove', this.onMouseMove);
          return this.raf = requestAnimationFrame(this.onAnimationFrame);
        }
      };

      CirclesUI.prototype.disableDrag = function() {
        if (this.dragging) {
          this.dragging = false;
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

      CirclesUI.prototype.setCirclePosition = function(circle, forceUpdate) {
        if (circle.x > -this.circleDiameter && circle.x < this.ew + this.circleDiameter && circle.y > -this.circleDiameter && circle.y < this.eh + this.circleDiameter) {
          addClass(circle, this.classVisible);
          if (circle.x > this.circleDiameter * 1 / 2 && circle.x < this.ew - this.circleDiameter * 3 / 2 && circle.y > this.circleDiameter * 1 / 3 && circle.y < this.eh - this.circleDiameter * 3 / 2) {
            if (!hasClass(circle, this.classBig)) {
              addClass(circle, this.classBig);
              return this.setPositionAndScale(circle, circle.x, circle.y, 1, true);
            } else {
              return this.setPositionAndScale(circle, circle.x, circle.y, 1, forceUpdate);
            }
          } else if (hasClass(circle, this.classBig)) {
            removeClass(circle, this.classBig);
            return this.setPositionAndScale(circle, circle.x, circle.y, 0.33333, true);
          } else {
            return this.setPositionAndScale(circle, circle.x, circle.y, 0.33333, forceUpdate);
          }
        } else if (hasClass(circle, this.classVisible)) {
          return removeClass(circle, this.classVisible);
        }
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
        this.disableDrag();
        i = 0;
        while (Math.abs(this.vx) > 0 && Math.abs(this.vx) > 0 && i < 50) {
          this.raf = requestAnimationFrame(this.onAnimationFrame);
          i++;
        }
        return cancelAnimationFrame(this.raf);
      };

      window[NAME] = CirclesUI;

      return CirclesUI;

    })();
  })(window, document);

  (function(window, document) {
    var FullScreen, THRESHOLD_DISTANCE, THRESHOLD_TIME;
    THRESHOLD_DISTANCE = 75;
    THRESHOLD_TIME = 400;
    FullScreen = (function() {
      function FullScreen(element, background) {
        this.element = element;
        this.background = background;
        this.classNameExpanded = 'expanded';
        this.classNameAnimating = 'animating';
        this.activeTouch = null;
        this.activeTouchX = null;
        this.activeTouchY = null;
        this.activeTouchStart = null;
        this.circle = this.element.querySelector('.circle');
        this.close = this.element.querySelector('.close');
        this.content = this.element.querySelector('.content');
        this.expanded = false;
        this.animating = false;
        this.onExpand = this.onExpand.bind(this);
        this.onClose = this.onClose.bind(this);
        this.initialise();
      }

      FullScreen.prototype.initialise = function() {
        this.circle.addEventListener('click', this.onExpand);
        this.circle.addEventListener('touchstart', this.onTouch);
        this.circle.addEventListener('touchend', this.onTouch);
        this.close.addEventListener('click', this.onClose);
        return this.close.addEventListener("touchend", this.onClose);
      };

      FullScreen.prototype.getCoordinatesFromEvent = function(event) {
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

      FullScreen.prototype.onTouch = function(event) {
        var clientX, clientY, _ref, _ref1;
        if (!this.activeTouch) {
          this.activeTouch = event.changedTouches[0].identifier;
          _ref = this.getCoordinatesFromEvent(event), clientX = _ref.clientX, clientY = _ref.clientY;
          this.activeTouchX = clientX;
          this.activeTouchY = clientX;
          return this.activeTouchStart = event.timeStamp;
        } else {
          _ref1 = this.getCoordinatesFromEvent(event), clientX = _ref1.clientX, clientY = _ref1.clientY;
          if (Math.abs(this.activeTouchX - clientX) < THRESHOLD_DISTANCE && Math.abs(this.activeTouchY - clientY) < THRESHOLD_DISTANCE && event.timeStamp - this.activeTouchStart < THRESHOLD_TIME) {
            onExpand(event);
          }
          this.activeTouch = null;
          this.activeTouchX = null;
          this.activeTouchY = null;
          return this.activeTouchStart = null;
        }
      };

      FullScreen.prototype.onExpand = function(event) {
        var self;
        event.preventDefault();
        if (!this.expanded && !this.animating) {
          this.background.stop();
          this.expanded = true;
          this.animating = true;
          classie.addClass(this.element, this.classNameExpanded);
          classie.addClass(this.element, this.classNameAnimating);
          self = this;
          return setTimeout((function() {
            self.animating = false;
            return classie.removeClass(self.element, self.classNameAnimating);
          }), 300);
        }
      };

      FullScreen.prototype.onClose = function(event) {
        var self;
        event.preventDefault();
        if (this.expanded && !this.animating) {
          this.animating = true;
          classie.removeClass(this.element, this.classNameExpanded);
          classie.addClass(this.element, this.classNameAnimating);
          this.expanded = false;
          self = this;
          return setTimeout((function() {
            self.background.start();
            self.animating = false;
            return classie.removeClass(self.element, self.classNameAnimating);
          }), 300);
        }
      };

      return FullScreen;

    })();
    return window.FullScreen = FullScreen;
  })(window, document);

  (function() {
    var EventEmitter, alias, indexOfListener;
    indexOfListener = function(listeners, listener) {
      var i;
      i = listeners.length;
      if ((function() {
        var _results;
        _results = [];
        while (i--) {
          _results.push(listeners[i].listener === listener);
        }
        return _results;
      })()) {
        return i;
      }
      return -1;
    };
    alias = function(name) {
      var aliasClosure;
      return aliasClosure = function() {
        return this[name].apply(this, arguments);
      };
    };
    EventEmitter = (function() {
      function EventEmitter() {}

      EventEmitter.prototype.getListeners = function(evt) {
        var events, key, response;
        events = this._getEvents();
        response = void 0;
        key = void 0;
        if (typeof evt === "object") {
          response = {};
          for (key in events) {
            if (events.hasOwnProperty(key) && evt.test(key)) {
              response[key] = events[key];
            }
          }
        } else {
          response = events[evt] || (events[evt] = []);
        }
        return response;
      };

      EventEmitter.prototype.flattenListeners = function(listeners) {
        var flatListeners, i;
        flatListeners = [];
        i = 0;
        while (i < listeners.length) {
          flatListeners.push(listeners[i].listener);
          i += 1;
        }
        return flatListeners;
      };

      EventEmitter.prototype.getListenersAsObject = function(evt) {
        var listeners, response;
        listeners = this.getListeners(evt);
        response = void 0;
        if (listeners instanceof Array) {
          response = {};
          response[evt] = listeners;
        }
        return response || listeners;
      };

      EventEmitter.prototype.addListener = function(evt, listener) {
        var key, listenerIsWrapped, listeners;
        listeners = this.getListenersAsObject(evt);
        listenerIsWrapped = typeof listener === "object";
        key = void 0;
        for (key in listeners) {
          if (listeners.hasOwnProperty(key) && indexOfListener(listeners[key], listener) === -1) {
            listeners[key].push((listenerIsWrapped ? listener : {
              listener: listener,
              once: false
            }));
          }
        }
        return this;
      };

      EventEmitter.prototype.on = alias("addListener");

      EventEmitter.prototype.addOnceListener = function(evt, listener) {
        return this.addListener(evt, {
          listener: listener,
          once: true
        });
      };

      EventEmitter.prototype.once = alias("addOnceListener");

      EventEmitter.prototype.defineEvent = function(evt) {
        this.getListeners(evt);
        return this;
      };

      EventEmitter.prototype.defineEvents = function(evts) {
        var i;
        i = 0;
        while (i < evts.length) {
          this.defineEvent(evts[i]);
          i += 1;
        }
        return this;
      };

      EventEmitter.prototype.removeListener = function(evt, listener) {
        var index, key, listeners;
        listeners = this.getListenersAsObject(evt);
        index = void 0;
        key = void 0;
        for (key in listeners) {
          if (listeners.hasOwnProperty(key)) {
            index = indexOfListener(listeners[key], listener);
            if (index !== -1) {
              listeners[key].splice(index, 1);
            }
          }
        }
        return this;
      };

      EventEmitter.prototype.off = alias("removeListener");

      EventEmitter.prototype.addListeners = function(evt, listeners) {
        return this.manipulateListeners(false, evt, listeners);
      };

      EventEmitter.prototype.removeListeners = function(evt, listeners) {
        return this.manipulateListeners(true, evt, listeners);
      };

      EventEmitter.prototype.manipulateListeners = function(remove, evt, listeners) {
        var i, multiple, single, value;
        single = remove ? this.removeListener : this.addListener;
        multiple = remove ? this.removeListeners : this.addListeners;
        if (typeof evt === "object" && (!(evt instanceof RegExp))) {
          for (i in evt) {
            if (evt.hasOwnProperty(i) && (value = evt[i])) {
              if (typeof value === "function") {
                single.call(this, i, value);
              } else {
                multiple.call(this, i, value);
              }
            }
          }
        } else {
          i = listeners.length;
          while (i--) {
            single.call(this, evt, listeners[i]);
          }
        }
        return this;
      };

      EventEmitter.prototype.removeEvent = function(evt) {
        var events, key, type;
        type = typeof evt;
        events = this._getEvents();
        if (type === "string") {
          delete events[evt];
        } else if (type === "object") {
          for (key in events) {
            if (events.hasOwnProperty(key) && evt.test(key)) {
              delete events[key];
            }
          }
        } else {
          delete this._events;
        }
        return this;
      };

      EventEmitter.prototype.emitEvent = function(evt, args) {
        var i, key, listener, listeners, response;
        listeners = this.getListenersAsObject(evt);
        for (key in listeners) {
          if (listeners.hasOwnProperty(key)) {
            i = listeners[key].length;
            while (i--) {
              listener = listeners[key][i];
              response = listener.listener.apply(this, args || []);
              if (response === this._getOnceReturnValue() || listener.once === true) {
                this.removeListener(evt, listener.listener);
              }
            }
          }
        }
        return this;
      };

      EventEmitter.prototype.trigger = alias("emitEvent");

      EventEmitter.prototype.emit = function(evt) {
        var args;
        args = Array.prototype.slice.call(arguments, 1);
        return this.emitEvent(evt, args);
      };

      EventEmitter.prototype.setOnceReturnValue = function(value) {
        this._onceReturnValue = value;
        return this;
      };

      EventEmitter.prototype._getOnceReturnValue = function() {
        if (this.hasOwnProperty("_onceReturnValue")) {
          return this._onceReturnValue;
        } else {
          return true;
        }
      };

      EventEmitter.prototype._getEvents = function() {
        return this._events || (this._events = {});
      };

      return EventEmitter;

    })();
    if (typeof define === "function" && define.amd) {
      define("eventEmitter/EventEmitter", [], function() {
        return EventEmitter;
      });
    } else if (typeof module === "object" && module.exports) {
      module.exports = EventEmitter;
    } else {
      this.EventEmitter = EventEmitter;
    }
  }).call(this);

  (function(window) {
    var bind, docElem, eventie, unbind;
    docElem = document.documentElement;
    bind = function() {};
    if (docElem.addEventListener) {
      bind = function(obj, type, fn) {
        obj.addEventListener(type, fn, false);
      };
    } else if (docElem.attachEvent) {
      bind = function(obj, type, fn) {
        obj[type + fn] = (fn.handleEvent ? function() {
          var event;
          event = window.event;
          event.target = event.target || event.srcElement;
          fn.handleEvent.call(fn, event);
        } : function() {
          var event;
          event = window.event;
          event.target = event.target || event.srcElement;
          fn.call(obj, event);
        });
        obj.attachEvent("on" + type, obj[type + fn]);
      };
    }
    unbind = function() {};
    if (docElem.removeEventListener) {
      unbind = function(obj, type, fn) {
        obj.removeEventListener(type, fn, false);
      };
    } else if (docElem.detachEvent) {
      unbind = function(obj, type, fn) {
        var err;
        obj.detachEvent("on" + type, obj[type + fn]);
        try {
          delete obj[type + fn];
        } catch (_error) {
          err = _error;
          obj[type + fn] = 'undefined';
        }
      };
    }
    eventie = {
      bind: bind,
      unbind: unbind
    };
    if (typeof define === "function" && define.amd) {
      define("eventie/eventie", eventie);
    } else {
      window.eventie = eventie;
    }
  })(this);

  (function(window) {
    var docElemStyle, getStyleProperty, prefixes;
    getStyleProperty = function(propName) {
      var i, len, prefixed;
      if (!propName) {
        return;
      }
      if (typeof docElemStyle[propName] === "string") {
        return propName;
      }
      propName = propName.charAt(0).toUpperCase() + propName.slice(1);
      prefixed = void 0;
      i = 0;
      len = prefixes.length;
      while (i < len) {
        prefixed = prefixes[i] + propName;
        if (typeof docElemStyle[prefixed] === "string") {
          return prefixed;
        }
        i++;
      }
    };
    prefixes = "Webkit Moz ms Ms O".split(" ");
    docElemStyle = document.documentElement.style;
    if (typeof define === "function" && define.amd) {
      define("get-style-property/get-style-property", [], function() {
        return getStyleProperty;
      });
    } else {
      window.getStyleProperty = getStyleProperty;
    }
  })(window);


  /**
  getSize v1.1.4
  measure size of elements
   */

  (function(window, undefined_) {
    var defView, defineGetSize, getStyle, getStyleSize, getZeroSize, measurements;
    getStyleSize = function(value) {
      var isValid, num;
      num = parseFloat(value);
      isValid = value.indexOf("%") === -1 && !isNaN(num);
      return isValid && num;
    };
    getZeroSize = function() {
      var i, len, measurement, size;
      size = {
        width: 0,
        height: 0,
        innerWidth: 0,
        innerHeight: 0,
        outerWidth: 0,
        outerHeight: 0
      };
      i = 0;
      len = measurements.length;
      while (i < len) {
        measurement = measurements[i];
        size[measurement] = 0;
        i++;
      }
      return size;
    };
    defineGetSize = function(getStyleProperty) {

      /**
      WebKit measures the outer-width on style.width on border-box elems
      IE & Firefox measures the inner-width
       */
      var boxSizingProp, getSize, isBoxSizeOuter;
      getSize = function(elem) {
        var borderHeight, borderWidth, i, isBorderBox, isBorderBoxSizeOuter, len, marginHeight, marginWidth, measurement, num, paddingHeight, paddingWidth, size, style, styleHeight, styleWidth, value;
        if (typeof elem === "string") {
          elem = document.querySelector(elem);
        }
        if (!elem || typeof elem !== "object" || !elem.nodeType) {
          return;
        }
        style = getStyle(elem);
        if (style.display === "none") {
          return getZeroSize();
        }
        size = {};
        size.width = elem.offsetWidth;
        size.height = elem.offsetHeight;
        isBorderBox = size.isBorderBox = !!(boxSizingProp && style[boxSizingProp] && style[boxSizingProp] === "border-box");
        i = 0;
        len = measurements.length;
        while (i < len) {
          measurement = measurements[i];
          value = style[measurement];
          num = parseFloat(value);
          size[measurement] = (!isNaN(num) ? num : 0);
          i++;
        }
        paddingWidth = size.paddingLeft + size.paddingRight;
        paddingHeight = size.paddingTop + size.paddingBottom;
        marginWidth = size.marginLeft + size.marginRight;
        marginHeight = size.marginTop + size.marginBottom;
        borderWidth = size.borderLeftWidth + size.borderRightWidth;
        borderHeight = size.borderTopWidth + size.borderBottomWidth;
        isBorderBoxSizeOuter = isBorderBox && isBoxSizeOuter;
        styleWidth = getStyleSize(style.width);
        if (styleWidth !== false) {
          size.width = styleWidth + (isBorderBoxSizeOuter ? 0 : paddingWidth + borderWidth);
        }
        styleHeight = getStyleSize(style.height);
        if (styleHeight !== false) {
          size.height = styleHeight + (isBorderBoxSizeOuter ? 0 : paddingHeight + borderHeight);
        }
        size.innerWidth = size.width - (paddingWidth + borderWidth);
        size.innerHeight = size.height - (paddingHeight + borderHeight);
        size.outerWidth = size.width + marginWidth;
        size.outerHeight = size.height + marginHeight;
        return size;
      };
      boxSizingProp = getStyleProperty("boxSizing");
      isBoxSizeOuter = void 0;
      (function() {
        var body, div, style;
        if (!boxSizingProp) {
          return;
        }
        div = document.createElement("div");
        div.style.width = "200px";
        div.style.padding = "1px 2px 3px 4px";
        div.style.borderStyle = "solid";
        div.style.borderWidth = "1px 2px 3px 4px";
        div.style[boxSizingProp] = "border-box";
        body = document.body || document.documentElement;
        body.appendChild(div);
        style = getStyle(div);
        isBoxSizeOuter = getStyleSize(style.width) === 200;
        body.removeChild(div);
      })();
      return getSize;
    };
    defView = document.defaultView;
    getStyle = (defView && defView.getComputedStyle ? function(elem) {
      return defView.getComputedStyle(elem, null);
    } : function(elem) {
      return elem.currentStyle;
    });
    measurements = ["paddingLeft", "paddingRight", "paddingTop", "paddingBottom", "marginLeft", "marginRight", "marginTop", "marginBottom", "borderLeftWidth", "borderRightWidth", "borderTopWidth", "borderBottomWidth"];
    if (typeof define === "function" && define.amd) {
      define("get-size/get-size", ["get-style-property/get-style-property"], defineGetSize);
    } else {
      window.getSize = defineGetSize(window.getStyleProperty);
    }
  })(window);

  (function(window) {
    var cancelAnimationFrame, defView, document, draggabillyDefinition, extend, getStyle, i, isElement, isElementDOM2, isElementQuirky, lastTime, noop, prefix, prefixes, requestAnimationFrame;
    extend = function(a, b) {
      var prop;
      for (prop in b) {
        a[prop] = b[prop];
      }
      return a;
    };
    noop = function() {};
    draggabillyDefinition = function(classie, EventEmitter, eventie, getStyleProperty, getSize) {
      var Draggabilly, applyGrid, disableImgOndragstart, is3d, isIE8, noDragStart, postStartEvents, setPointerPoint, transformProperty, translate;
      noDragStart = function() {
        return false;
      };
      setPointerPoint = function(point, pointer) {
        point.x = pointer.pageX !== 'undefined' ? pointer.pageX : pointer.clientX;
        point.y = pointer.pageY !== 'undefined' ? pointer.pageY : pointer.clientY;
      };
      applyGrid = function(value, grid, method) {
        method = method || "round";
        if (grid) {
          return Math[method](value / grid) * grid;
        } else {
          return value;
        }
      };
      transformProperty = getStyleProperty("transform");
      is3d = !!getStyleProperty("perspective");
      isIE8 = "attachEvent" in document.documentElement;
      disableImgOndragstart = (!isIE8 ? noop : function(handle) {
        var i, images, img, len, _results;
        if (handle.nodeName === "IMG") {
          handle.ondragstart = noDragStart;
        }
        images = handle.querySelectorAll("img");
        i = 0;
        len = images.length;
        _results = [];
        while (i < len) {
          img = images[i];
          img.ondragstart = noDragStart;
          _results.push(i++);
        }
        return _results;
      });
      translate = (is3d ? function(x, y) {
        return "translate3d( " + x + "px, " + y + "px, 0)";
      } : function(x, y) {
        return "translate( " + x + "px, " + y + "px)";
      });
      postStartEvents = {
        mousedown: [],
        touchstart: [],
        pointerdown: [],
        MSPointerDown: []
      };
      Draggabilly = (function(_super) {
        __extends(Draggabilly, _super);

        function Draggabilly(element, options) {
          this.options = options;
          this.element = typeof element === "string" ? document.querySelector(element) : element;
          this.options = extend({}, this.options);
          extend(this.options, options);
          this._create();
        }

        Draggabilly.prototype._create = function() {
          var style;
          this.position = {};
          this._getPosition();
          this.startPoint = {
            x: 0,
            y: 0
          };
          this.dragPoint = {
            x: 0,
            y: 0
          };
          this.startPosition = extend({}, this.position);
          style = getStyle(this.element);
          if (style.position !== "relative" && style.position !== "absolute") {
            this.element.style.position = "relative";
          }
          this.enable();
          return this.setHandles();
        };

        Draggabilly.prototype.setHandles = function() {
          var handle, i, len, _results;
          this.handles = this.options.handle ? this.element.querySelectorAll(this.options.handle) : [this.element];
          i = 0;
          len = this.handles.length;
          _results = [];
          while (i < len) {
            handle = this.handles[i];
            if (window.navigator.pointerEnabled) {
              eventie.bind(handle, "pointerdown", this);
              handle.style.touchAction = "none";
            } else if (window.navigator.msPointerEnabled) {
              eventie.bind(handle, "MSPointerDown", this);
              handle.style.msTouchAction = "none";
            } else {
              eventie.bind(handle, "mousedown", this);
              eventie.bind(handle, "touchstart", this);
              disableImgOndragstart(handle);
            }
            _results.push(i++);
          }
          return _results;
        };

        Draggabilly.prototype._getPosition = function() {
          var style, x, y;
          style = getStyle(this.element);
          x = parseInt(style.left, 10);
          y = parseInt(style.top, 10);
          this.position.x = (isNaN(x) ? 0 : x);
          this.position.y = (isNaN(y) ? 0 : y);
          return this._addTransformPosition(style);
        };

        Draggabilly.prototype._addTransformPosition = function(style) {
          var matrixValues, transform, translateX, translateY, xIndex;
          if (!transformProperty) {
            return;
          }
          transform = style[transformProperty];
          if (transform.indexOf("matrix") !== 0) {
            return;
          }
          matrixValues = transform.split(",");
          xIndex = (transform.indexOf("matrix3d") === 0 ? 12 : 4);
          translateX = parseInt(matrixValues[xIndex], 10);
          translateY = parseInt(matrixValues[xIndex + 1], 10);
          this.position.x += translateX;
          return this.position.y += translateY;
        };

        Draggabilly.prototype.handleEvent = function(event) {
          var method;
          method = "on" + event.type;
          if (this[method]) {
            this[method](event);
          }
        };

        Draggabilly.prototype.getTouch = function(touches) {
          var i, len, touch;
          i = 0;
          len = touches.length;
          while (i < len) {
            touch = touches[i];
            if (touch.identifier === this.pointerIdentifier) {
              return touch;
            }
            i++;
          }
        };

        Draggabilly.prototype.onmousedown = function(event) {
          var button;
          button = event.button;
          if (button && (button !== 0 && button !== 1)) {
            return;
          }
          this.dragStart(event, event);
        };

        Draggabilly.prototype.ontouchstart = function(event) {
          if (this.isDragging) {
            return;
          }
          this.dragStart(event, event.changedTouches[0]);
        };

        Draggabilly.prototype.onMSPointerDown = function(event) {
          if (this.isDragging) {
            return;
          }
          this.dragStart(event, event);
        };

        Draggabilly.prototype.onpointerdown = function(event) {
          if (this.isDragging) {
            return;
          }
          this.dragStart(event, event);
        };

        Draggabilly.prototype.dragStart = function(event, pointer) {
          if (!this.isEnabled) {
            return;
          }
          if (event.preventDefault) {
            event.preventDefault();
          } else {
            event.returnValue = false;
          }
          this.pointerIdentifier = pointer.pointerId !== 'undefined' ? pointer.pointerId : pointer.identifier;
          this._getPosition();
          this.measureContainment();
          setPointerPoint(this.startPoint, pointer);
          this.startPosition.x = this.position.x;
          this.startPosition.y = this.position.y;
          this.setLeftTop();
          this.dragPoint.x = 0;
          this.dragPoint.y = 0;
          this._bindEvents({
            events: postStartEvents[event.type],
            node: (event.preventDefault ? window : document)
          });
          classie.addClass(this.element, "is-dragging");
          this.isDragging = true;
          this.emitEvent("dragStart", []);
          this.animate();
        };

        Draggabilly.prototype._bindEvents = function(args) {
          var event, i, len;
          i = 0;
          len = args.events.length;
          while (i < len) {
            event = args.events[i];
            eventie.bind(args.node, event, this);
            i++;
          }
          this._boundEvents = args;
        };

        Draggabilly.prototype._unbindEvents = function() {
          var args, event, i, len;
          args = this._boundEvents;
          if (!args || !args.events) {
            return;
          }
          i = 0;
          len = args.events.length;
          while (i < len) {
            event = args.events[i];
            eventie.unbind(args.node, event, this);
            i++;
          }
          return delete this._boundEvents;
        };

        Draggabilly.prototype.measureContainment = function() {
          var container, containerRect, containment, elemRect;
          containment = this.options.containment;
          if (!containment) {
            return;
          }
          this.size = getSize(this.element);
          elemRect = this.element.getBoundingClientRect();
          container = (isElement(containment) ? containment : (typeof containment === "string" ? document.querySelector(containment) : this.element.parentNode));
          this.containerSize = getSize(container);
          containerRect = container.getBoundingClientRect();
          return this.relativeStartPosition = {
            x: elemRect.left - containerRect.left,
            y: elemRect.top - containerRect.top
          };
        };

        Draggabilly.prototype.onmousemove = function(event) {
          this.dragMove(event, event);
        };

        Draggabilly.prototype.onMSPointerMove = function(event) {
          if (event.pointerId === this.pointerIdentifier) {
            this.dragMove(event, event);
          }
        };

        Draggabilly.prototype.onpointermove = function(event) {
          if (event.pointerId === this.pointerIdentifier) {
            this.dragMove(event, event);
          }
        };

        Draggabilly.prototype.ontouchmove = function(event) {
          var touch;
          touch = this.getTouch(event.changedTouches);
          if (touch) {
            this.dragMove(event, touch);
          }
        };

        Draggabilly.prototype.dragMove = function(event, pointer) {
          var dragX, dragY, grid, gridX, gridY;
          setPointerPoint(this.dragPoint, pointer);
          dragX = this.dragPoint.x - this.startPoint.x;
          dragY = this.dragPoint.y - this.startPoint.y;
          grid = this.options.grid;
          gridX = grid && grid[0];
          gridY = grid && grid[1];
          dragX = applyGrid(dragX, gridX);
          dragY = applyGrid(dragY, gridY);
          dragX = this.containDrag("x", dragX, gridX);
          dragY = this.containDrag("y", dragY, gridY);
          dragX = (this.options.axis === "y" ? 0 : dragX);
          dragY = (this.options.axis === "x" ? 0 : dragY);
          this.position.x = this.startPosition.x + dragX;
          this.position.y = this.startPosition.y + dragY;
          this.dragPoint.x = dragX;
          this.dragPoint.y = dragY;
          this.emitEvent("dragMove", []);
        };

        Draggabilly.prototype.containDrag = function(axis, drag, grid) {
          var max, measure, min, rel;
          if (!this.options.containment) {
            return drag;
          }
          measure = (axis === "x" ? "width" : "height");
          rel = this.relativeStartPosition[axis];
          min = applyGrid(-rel, grid, "ceil");
          max = this.containerSize[measure] - rel - this.size[measure];
          max = applyGrid(max, grid, "floor");
          return Math.min(max, Math.max(min, drag));
        };

        Draggabilly.prototype.onmouseup = function(event) {
          return this.dragEnd(event, event);
        };

        Draggabilly.prototype.onMSPointerUp = function(event) {
          if (event.pointerId === this.pointerIdentifier) {
            return this.dragEnd(event, event);
          }
        };

        Draggabilly.prototype.onpointerup = function(event) {
          if (event.pointerId === this.pointerIdentifier) {
            return this.dragEnd(event, event);
          }
        };

        Draggabilly.prototype.ontouchend = function(event) {
          var touch;
          touch = this.getTouch(event.changedTouches);
          if (touch) {
            return this.dragEnd(event, touch);
          }
        };

        Draggabilly.prototype.dragEnd = function(event, pointer) {
          this.isDragging = false;
          delete this.pointerIdentifier;
          if (transformProperty) {
            this.element.style[transformProperty] = "";
            this.setLeftTop();
          }
          this._unbindEvents();
          classie.removeClass(this.element, "is-dragging");
          return this.emitEvent("dragEnd", []);
        };

        Draggabilly.prototype.onMSPointerCancel = function(event) {
          if (event.pointerId === this.pointerIdentifier) {
            return this.dragEnd(event, event);
          }
        };

        Draggabilly.prototype.onpointercancel = function(event) {
          if (event.pointerId === this.pointerIdentifier) {
            return this.dragEnd(event, event);
          }
        };

        Draggabilly.prototype.ontouchcancel = function(event) {
          var touch;
          touch = this.getTouch(event.changedTouches);
          return this.dragEnd(event, touch);
        };

        Draggabilly.prototype.animate = function() {
          var animateFrame, _this;
          if (!this.isDragging) {
            return;
          }
          this.positionDrag();
          _this = this;
          return requestAnimationFrame(animateFrame = function() {
            return _this.animate();
          });
        };

        Draggabilly.prototype.setLeftTop = function() {
          this.element.style.left = this.position.x + "px";
          return this.element.style.top = this.position.y + "px";
        };

        Draggabilly.prototype.positionDrag = transformProperty ? function() {
          return this.element.style[transformProperty] = translate(this.dragPoint.x, this.dragPoint.y);
        } : Draggabilly.setLeftTop;

        Draggabilly.prototype.enable = function() {
          return this.isEnabled = true;
        };

        Draggabilly.prototype.disable = function() {
          this.isEnabled = false;
          if (this.isDragging) {
            return this.dragEnd();
          }
        };

        return Draggabilly;

      })(EventEmitter);
      return Draggabilly;
    };
    document = window.document;
    defView = document.defaultView;
    getStyle = defView && defView.getComputedStyle ? function(elem) {
      return defView.getComputedStyle(elem, null);
    } : function(elem) {
      return elem.currentStyle;
    };
    isElement = typeof HTMLElement === "object" ? isElementDOM2 = function(obj) {
      return obj instanceof HTMLElement;
    } : isElementQuirky = function(obj) {
      return obj && typeof obj === "object" && obj.nodeType === 1 && typeof obj.nodeName === "string";
    };
    lastTime = 0;
    prefixes = "webkit moz ms o".split(" ");
    requestAnimationFrame = window.requestAnimationFrame;
    cancelAnimationFrame = window.cancelAnimationFrame;
    prefix = void 0;
    i = 0;
    while (i < prefixes.length) {
      if (requestAnimationFrame && cancelAnimationFrame) {
        break;
      }
      prefix = prefixes[i];
      requestAnimationFrame = requestAnimationFrame || window[prefix + "RequestAnimationFrame"];
      cancelAnimationFrame = cancelAnimationFrame || window[prefix + "CancelAnimationFrame"] || window[prefix + "CancelRequestAnimationFrame"];
      i++;
    }
    if (!requestAnimationFrame || !cancelAnimationFrame) {
      requestAnimationFrame = function(callback) {
        var currTime, id, timeToCall;
        currTime = new Date().getTime();
        timeToCall = Math.max(0, 16 - (currTime - lastTime));
        id = window.setTimeout(function() {
          callback(currTime + timeToCall);
        }, timeToCall);
        lastTime = currTime + timeToCall;
        return id;
      };
      cancelAnimationFrame = function(id) {
        window.clearTimeout(id);
      };
    }
    return window.Draggabilly = draggabillyDefinition(window.classie, window.EventEmitter, window.eventie, window.getStyleProperty, window.getSize);
  })(window);


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

  (function(window, document) {
    var Signup;
    Signup = (function() {
      function Signup(form, options) {
        this.form = form;
        this.first_name = this.form.querySelector('#first_name');
        this.last_name = this.form.querySelector('#last_name');
        this.slug_name = this.form.querySelector('#slug_name');
        this.birthday = this.form.querySelector('#birthday');
        this.email = this.form.querySelector('#email');
        this.password = this.form.querySelector('#password');
        this.slug_changed = false;
        this.onFirstNameBlur = this.onFirstNameBlur.bind(this);
        this.onLastNameBlur = this.onLastNameBlur.bind(this);
        this.onNamesChange = this.onNamesChange.bind(this);
        this.onSlugNameBlur = this.onSlugNameBlur.bind(this);
        this.onBirthdayBlur = this.onBirthdayBlur.bind(this);
        this.onPasswordBlur = this.onPasswordBlur.bind(this);
        this.onSubmit = this.onSubmit.bind(this);
        this.initialise();
      }

      Signup.prototype.initialise = function() {
        this.first_name.addEventListener('blur', this.onFirstNameBlur);
        this.last_name.addEventListener('blur', this.onLastNameBlur);
        this.first_name.addEventListener('input', this.onNamesChange);
        this.last_name.addEventListener('input', this.onNamesChange);
        this.slug_name.addEventListener('blur', this.onSlugNameBlur);
        this.birthday.addEventListener('blur', this.onBirthdayBlur);
        this.password.addEventListener('blur', this.onPasswordBlur);
        return this.form.addEventListener('submit', this.onSubmit);
      };

      Signup.prototype.checkFirstName = function() {
        if (this.first_name.value.length > 1) {
          if (classie.hasClass(this.first_name, 'error')) {
            classie.removeClass(this.first_name, 'error');
          }
          return true;
        } else {
          classie.addClass(this.first_name, 'error');
          return false;
        }
      };

      Signup.prototype.checkLastName = function() {
        if (this.last_name.value.length > 1) {
          if (classie.hasClass(this.last_name, 'error')) {
            classie.removeClass(this.last_name, 'error');
          }
          return true;
        } else {
          classie.addClass(this.last_name, 'error');
          return false;
        }
      };

      Signup.prototype.checkPassword = function() {
        if (this.password.value.length > 5) {
          if (classie.hasClass(this.password, 'error')) {
            classie.removeClass(this.password, 'error');
          }
          return true;
        } else {
          classie.addClass(this.password, 'error');
          return false;
        }
      };

      Signup.prototype.checkSlugName = function() {
        if (this.slug_name.value.length > 1 && this.checkSluggish()) {
          if (classie.hasClass(this.slug_name, 'error')) {
            classie.removeClass(this.slug_name, 'error');
          }
          return true;
        } else {
          classie.addClass(this.slug_name, 'error');
          return false;
        }
      };

      Signup.prototype.checkSluggish = function() {
        var re;
        re = /^[a-z0-9\-]*$/;
        return re.test(this.slug_name.value);
      };

      Signup.prototype.checkBirthday = function() {
        var parts, re;
        re = /^[0-3][0-9][\/][0-1][0-9][\/][1-2][0-9]{3}$/;
        parts = this.birthday.value.split('/');
        if (re.test(this.birthday.value) && ((new Date(parts[2], parts[1] - 1, parts[0])) != null)) {
          if (classie.hasClass(this.birthday, 'error')) {
            classie.removeClass(this.birthday, 'error');
          }
          return true;
        } else {
          classie.addClass(this.birthday, 'error');
          return false;
        }
      };

      Signup.prototype.generateSlug = function() {
        var base;
        base = this.last_name.value.length > 0 && this.first_name.value.length > 0 ? this.first_name.value + '-' + this.last_name.value : this.first_name.value.length > 0 ? this.first_name.value : this.last_name.value;
        return base.toString().toLowerCase().replace(/\s+/g, '-').replace(/[^\w\-]+/g, '').replace(/\-\-+/g, '-').replace(/^-+/, '').replace(/-+$/, '');
      };

      Signup.prototype.onFirstNameBlur = function() {
        return this.checkFirstName();
      };

      Signup.prototype.onLastNameBlur = function() {
        return this.checkLastName();
      };

      Signup.prototype.onNamesChange = function() {
        if (!this.slug_changed) {
          return this.slug_name.value = this.generateSlug();
        }
      };

      Signup.prototype.onSlugNameBlur = function() {
        this.slug_changed = true;
        return this.checkSlugName();
      };

      Signup.prototype.onBirthdayBlur = function() {
        return this.checkBirthday();
      };

      Signup.prototype.onPasswordBlur = function() {
        return this.checkPassword();
      };

      Signup.prototype.onSubmit = function(event) {
        if (!(this.checkFirstName() && this.checkLastName() && this.checkSlugName() && this.checkBirthday() && this.checkPassword())) {
          return event.preventDefault();
        }
      };

      return Signup;

    })();
    return window.Signup = Signup;
  })(window, document);

}).call(this);

//# sourceMappingURL=script.js.map
