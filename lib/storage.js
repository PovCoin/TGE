const Moment = require("moment");

var storage = {
    setProdMode : function(opts){
        this.ownerAddress = '0x651617c5576c489c3ca5cdf11257b246aabde925';

        // Адрес, куда будут переводится платежи за токены
        this.destinationAddress = '0xa64f578970e34ebbcfefa3b7a3be3fef819a2949';

        this.startDate = "2018-06-28 00:00:00";
        this.endDate = "2019-06-22 23:59:59";

        this.tokenSymbol = 'POVR';
        this.tokenName = 'POVCoin Token';
        this.tokenDecimals = 18;

        this.startDateTimestamp = Moment(this.startDate).unix();
        this.endDateTimestamp = Moment(this.endDate).unix();
    },

    setDevMode : function(opts){
        opts.ownerAddress = opts.ownerAddress || '0x0';
        this.ownerAddress = opts.ownerAddress;

        // Адрес, куда будут переводится платежи за токены
        this.destinationAddress = opts.tokenWalletAddress || '0x0';

        this.tokenSymbol = 'POVR';
        this.tokenName = 'POVCoin Token';
        this.tokenDecimals = 18;

        this.startDateTimestamp = Moment().add(1, "days").unix();
        this.endDateTimestamp = Moment().add(5, "days").unix();

        this.startDate = Moment.unix(this.startDateTimestamp).format("YYYY-MM-DD HH:mm:ss");
        this.endDate = Moment.unix(this.endDateTimestamp).format("YYYY-MM-DD HH:mm:ss");
    }
};

module.exports = storage;