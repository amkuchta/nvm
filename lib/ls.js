var fs = require('fs'),
    _ = require('lodash'),
    colors = require('colors'),
    path = require("path"),
    common = require('./common'),
    request = require('request');

module.exports = {
    sort: function(versions) {
        function sort(left, right, index) {
            if (Number(left[index]) === Number(right[index])) {
                return (index === 2 ? 0 : sort(left, right, index + 1));
            }
            return (Number(left[index]) > Number(right[index]) ? 1 : -1);
        }

        if (_.size(versions) <= 0 || _.isArray(versions) === false) {
            return versions;
        }

        return versions.sort(function(left, right) {
            return sort(
                left.substr(1).split('.'),
                right.substr(1).split('.'),
                0
            );
        });
    },

    local: function() {
        var nvmDir = common.getNvmDir(),
            versions = [];

        if (fs.existsSync(nvmDir) && fs.lstatSync(nvmDir).isDirectory()) {
            versions = this.sort(fs.readdirSync(nvmDir));
        }

        let linkVersion;
        const link = process.env.NVM_LINK;
        if (link && fs.existsSync(link)) {
            linkVersion = path.basename(fs.readlinkSync(link))
        }

        _.each(versions, function(version) {
            if (version === path.basename(link)) {
                return;
            }
            let linked = "";
            if (linkVersion === version) {
                linked = "switched";
            }
            if (process.env.NVM_USE === version) {
                console.log('* %s', version.green, linked.green);
            } else {
                console.log(version, linked.green);
            }
        });
    },

    remote: function() {
        var that = this;

        request.get('http://nodejs.org/dist/', function(error, response, body) {
            var versions = [];
            if (error === null && response.statusCode === 200) {
                versions = that.sort(
                    _.uniq(
                        _.filter(
                            body.match(/v[0-9]+.[0-9]+.[0-9]+/gi),
                            function(version) {
                                return (/^(v0.[0-4].[0-9]+)|(v0.5.0)$/i.test(version) === false);
                            }
                        )
                    )
                );
            }
            _.each(versions, function(version) {
                console.log(version);
            });
        });
    }
};