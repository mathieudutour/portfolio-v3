(function() {
  var lastTime, vendor, vendors, _fn, _i, _len,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

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
    var CirclesUI, DEFAULTS, NAME;
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
          } : this.transform2DSupport ? function(element, x, y, s, updateS) {
            var circle;
            x = x.toFixed(this.precision) + 'px';
            y = y.toFixed(this.precision) + 'px';
            this.css(element, this.vendorPrefix.js + 'Transform', 'translate(' + x + ',' + y + ')');
            if (updateS) {
              circle = element.getElementsByClassName('circle');
              return this.css(circle[0], this.vendorPrefix.js + 'Transform', 'scale(' + s + ',' + s + ')');
            }
          } : function(element, x, y, s, updateS) {
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
    var addClass, classReg, classie, hasClass, removeClass;
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
      has: hasClass,
      addClass: addClass,
      add: addClass,
      removeClass: removeClass,
      remove: removeClass
    };
    return window.classie = classie;
  })(window, document);


  /*
   * Draggable.coffee
   * @author Mathieu Dutour - @MathieuDutour
   * @description Drag an object
   */

  (function(window, document) {
    var DEFAULTS, Draggable, NAME;
    NAME = 'Draggable';
    DEFAULTS = {
      axis: null,
      containment: false,
      grid: [1, 1],
      handle: false,
      precision: 1,
      classDragging: "is-dragging",
      callbackDragStart: function() {},
      callbackDragging: function() {},
      callbackDrop: function() {},
      acceptDrop: function() {
        return true;
      }
    };
    return Draggable = (function() {
      function Draggable(element, options) {
        var data, key, _ref;
        this.element = element;
        data = {
          axis: this.data(this.element, 'wrap'),
          containment: this.data(this.element, 'relative-input'),
          handle: this.data(this.element, 'clipe-relative-input'),
          precision: this.data(this.element, 'invert-x'),
          classDragging: this.data(this.element, 'invert-y')
        };
        for (key in data) {
          if (data[key] === null) {
            delete data[key];
          }
        }
        this.extend(this, DEFAULTS, options, data);
        this.handle = this.element;
        this.started = false;
        this.dragging = false;
        this.raf = null;
        this.bounds = null;
        this.ex = 0;
        this.ey = 0;
        this.ew = 0;
        this.eh = 0;
        this.ww = 0;
        this.wh = 0;
        this.fix = 0;
        this.fiy = 0;
        this.ix = 0;
        this.iy = 0;
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
        this.setPosition = this.transform3DSupport ? function(x, y) {
          x = x.toFixed(this.precision) + 'px';
          y = y.toFixed(this.precision) + 'px';
          return this.css(this.element, this.vendorPrefix.js + 'Transform', 'translate3d(' + x + ',' + y + ',0)');
        } : this.transform2DSupport ? function(element, x, y, s) {
          x = x.toFixed(this.precision) + 'px';
          y = y.toFixed(this.precision) + 'px';
          return this.css(this.element, this.vendorPrefix.js + 'Transform', 'translate(' + x + ',' + y + ')');
        } : function(element, x, y, s) {
          x = x.toFixed(this.precision) + 'px';
          y = y.toFixed(this.precision) + 'px';
          this.element.style.left = x;
          return this.element.style.top = y;
        };
        this.onMouseDown = this.onMouseDown.bind(this);
        this.onMouseMove = this.onMouseMove.bind(this);
        this.onMouseUp = this.onMouseUp.bind(this);
        this.onAnimationFrame = this.onAnimationFrame.bind(this);
        this.onWindowResize = this.onWindowResize.bind(this);
        this.initialise();
      }

      Draggable.prototype.extend = function() {
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

      Draggable.prototype.data = function(element, name) {
        return this.deserialize(element.getAttribute('data-' + name));
      };

      Draggable.prototype.deserialize = function(value) {
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

      Draggable.prototype.onAnimationFrame = function(now) {
        this.setPosition(this.ix - this.fix - this.offsetx, this.iy - this.fiy - this.offsety);
        return this.raf = requestAnimationFrame(this.onAnimationFrame);
      };

      Draggable.prototype.getComputedTranslate = function(obj) {
        var mat, style, transform;
        if (!window.getComputedStyle) {
          return;
        }
        style = getComputedStyle(obj);
        transform = style.transform || style.webkitTransform || style.mozTransform;
        mat = transform.match(/^matrix3d\((.+)\)$/);
        if (mat) {
          return [parseFloat(mat[1].split(', ')[12]), parseFloat(mat[1].split(', ')[13])];
        }
        mat = transform.match(/^matrix\((.+)\)$/);
        if (mat) {
          return [parseFloat(mat[1].split(', ')[4]), parseFloat(mat[1].split(', ')[5])];
        } else {
          return [0, 0];
        }
      };

      Draggable.prototype.onMouseDown = function(event) {
        var clientX, clientY, _ref, _ref1;
        if (!this.dragging) {
          if ((event.changedTouches != null) && event.changedTouches.length > 0) {
            this.activeTouch = event.changedTouches[0].identifier;
          } else {
            event.preventDefault();
          }
          _ref = this.getCoordinatesFromEvent(event), clientX = _ref.clientX, clientY = _ref.clientY;
          this.fix = this.ix = clientX;
          this.fiy = this.iy = clientY;
          _ref1 = this.getComputedTranslate(this.element), this.offsetx = _ref1[0], this.offsety = _ref1[1];
          this.enableDrag();
          return this.callbackDragStart(event);
        }
      };

      Draggable.prototype.onMouseMove = function(event) {
        var clientX, clientY, _ref;
        _ref = this.getCoordinatesFromEvent(event), clientX = _ref.clientX, clientY = _ref.clientY;
        this.ix = clientX;
        this.iy = clientY;
        return this.callbackDragging(event);
      };

      Draggable.prototype.initialise = function() {
        var style;
        this.updateDimensions();
        if (this.transform3DSupport) {
          this.accelerate(this.element);
        }
        style = window.getComputedStyle(this.element);
        if (style.getPropertyValue('position') === 'static') {
          this.element.style.position = 'relative';
        }
        return this.start();
      };

      Draggable.prototype.start = function() {
        if (!this.started) {
          this.started = true;
          this.handle.addEventListener('mousedown', this.onMouseDown);
          this.handle.addEventListener('mouseup', this.onMouseUp);
          this.handle.addEventListener('touchstart', this.onMouseDown);
          return this.handle.addEventListener('touchend', this.onMouseUp);
        }
      };

      Draggable.prototype.stop = function() {
        if (this.started) {
          this.started = false;
          cancelAnimationFrame(this.raf);
          this.handle.removeEventListener('mousedown', this.onMouseDown);
          this.handle.removeEventListener('mouseup', this.onMouseUp);
          this.handle.removeEventListener('touchstart', this.onMouseDown);
          return this.handle.removeEventListener('touchend', this.onMouseUp);
        }
      };

      Draggable.prototype.updateDimensions = function() {
        this.ww = window.innerWidth;
        this.wh = window.innerHeight;
        return this.updateBounds();
      };

      Draggable.prototype.updateBounds = function() {
        this.bounds = this.element.parentNode.getBoundingClientRect();
        this.ex = this.bounds.left;
        this.ey = this.bounds.top;
        this.ew = this.bounds.width;
        return this.eh = this.bounds.height;
      };

      Draggable.prototype.enableDrag = function() {
        if (!this.dragging) {
          this.dragging = true;
          classie.add(this.element, this.classDragging);
          window.addEventListener('mousemove', this.onMouseMove);
          window.addEventListener('touchmove', this.onMouseMove);
          return this.raf = requestAnimationFrame(this.onAnimationFrame);
        }
      };

      Draggable.prototype.disableDrag = function() {
        if (this.dragging) {
          this.dragging = false;
          classie.remove(this.element, this.classDragging);
          window.removeEventListener('mousemove', this.onMouseMove);
          return window.removeEventListener('touchmove', this.onMouseMove);
        }
      };

      Draggable.prototype.css = function(element, property, value) {
        return element.style[property] = value;
      };

      Draggable.prototype.accelerate = function(element) {
        return this.css(element, this.vendorPrefix.transform, 'translate3d(0,0,0)');
      };

      Draggable.prototype.onWindowResize = function(event) {
        return this.updateDimensions();
      };

      Draggable.prototype.getCoordinatesFromEvent = function(event) {
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

      Draggable.prototype.onMouseUp = function(event) {
        this.activeTouch = null;
        this.disableDrag();
        cancelAnimationFrame(this.raf);
        return this.callbackDrop(event);
      };

      window[NAME] = Draggable;

      return Draggable;

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
